#cloud-config
package_update: true
package_upgrade: false
packages:
  - nodejs
  - npm

write_files:
  - path: /opt/app/server.js
    permissions: '0644'
    owner: root:root
    encoding: b64
    content: ${app_source_b64}

  - path: /opt/app/starter-app.env
    permissions: '0600'
    owner: root:root
    encoding: b64
    content: ${app_env_b64}

  - path: /etc/systemd/system/starter-app.service
    permissions: '0644'
    owner: root:root
    content: |
      [Unit]
      Description=OpenTofu starter - Node.js status app
      After=network.target

      [Service]
      EnvironmentFile=/opt/app/starter-app.env
      ExecStart=/usr/bin/node /opt/app/server.js
      Restart=always
      RestartSec=3
      User=root
      WorkingDirectory=/opt/app

      [Install]
      WantedBy=multi-user.target

runcmd:
  - systemctl daemon-reload
  - systemctl enable starter-app.service
  - systemctl restart starter-app.service

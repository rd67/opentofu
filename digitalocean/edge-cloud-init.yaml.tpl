#cloud-config
package_update: true
package_upgrade: false
packages:
  - nginx

write_files:
  - path: /etc/nginx/sites-available/default
    permissions: '0644'
    owner: root:root
    content: |
      server {
        listen 80 default_server;

        location = /nodejs {
          proxy_pass http://${node_host}:${node_port};
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location /nodejs/ {
          proxy_pass http://${node_host}:${node_port};
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location = /python {
          proxy_pass http://${python_host}:${python_port};
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location /python/ {
          proxy_pass http://${python_host}:${python_port};
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location = /php {
          proxy_pass http://${php_host}:${php_port};
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location /php/ {
          proxy_pass http://${php_host}:${php_port};
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        # Falls back to the Node.js app for any path that doesn't match a
        # location above (e.g. the bare "/") - a convenience, not the
        # documented contract. The documented, symmetric way to reach each
        # app is /nodejs, /python, /php.
        location / {
          proxy_pass http://${node_host}:${node_port};
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
      }

runcmd:
  - systemctl enable nginx
  - systemctl restart nginx

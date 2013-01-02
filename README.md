Asura
=====

Asura is an automated shell scripting tool especially for remote server operation.
Asura's goal is to provide "an executable operation manual for remote servers."

* Automates log-in to servers via ssh (Telnet support is planned)
* Automates user switching with "sudo su"

This is an alpha version. You should not use it for production servers.

Usage
=====
    ["hostname1", "hostname2"].each do |host|
      Asura::AsuraCommand.ssh(host, "password") do |ssh|
        ssh.sudo_su("dahlia") do
          ssh.bash do
            ssh.send_and_wait_for_prompt "crontab -l"
          end
        end
      end
    end

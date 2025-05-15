# Evergreen Server with sample data in 5 minutes

0. install Docker
1. pull the Evergreen server image
   ```
   docker compose pull
   ```
2. run the server
   ```
   docker compose up
   ```
3. WAIT PAITIENTLY until you see "PLAY RECAP"; this took me 3m26s:
   ```
   evergreen  | PLAY RECAP *********************************************************************
   evergreen  | localhost                  : ok=100  changed=76   unreachable=0    failed=0    skipped=2    rescued=0    ignored=22
   ```
4. access the server at
   * [OPAC at localhost:80](http://localhost/eg/opac/home)
   * [Staff Client at localhost:443](https://localhost/eg/staff/login).  You will have to click through the cert warnings.

https://www.home-assistant.io/integrations/http/#reverse-proxies

to get it to run, adjust the configuration.yaml in the config PVC to include

http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 10.42.0.0/16 # The IP address of the proxy server
    - 192.168.0.0/16 # IP address of local network
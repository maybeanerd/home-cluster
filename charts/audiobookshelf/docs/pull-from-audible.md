```bash
# Enter shell with all required tools
nix-shell -p ffmpeg fd jq audible-cli

# Log in/Create profile
audible quickstart

cd ~/Downloads

# Overview of files we will find
audible library list

# Download all files
audible download --all --aaxc

# Decrypt and reencode the files to m4b format
fd -e aaxc -x bash -c 'ffmpeg -y -audible_key "$(jq -r .content_license.license_response.key "{.}.voucher")" -audible_iv "$(jq -r .content_license.license_response.iv "{.}.voucher")" -i "{}" -c copy "{.}.m4b"'

# Delete raw audible files and vouchers, which we dont need anymore
fd -e aaxc -x rm
fd -e voucher -x rm
```

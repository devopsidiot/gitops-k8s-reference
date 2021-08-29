#!/bin/bash
sops --encrypt --config .sops.yaml decrypted.env-secrets.yaml > env-secrets.sops.yaml

#!/bin/bash
sops --decrypt env-secrets.yaml > env-secrets.yaml.decrypted.yaml

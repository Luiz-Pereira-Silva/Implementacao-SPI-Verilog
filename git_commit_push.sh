#!/bin/bash

echo "Nome do commit:"
read NOME_COMMIT

git add .
git status
git commit -m "$NOME_COMMIT"
git push -o origin.main

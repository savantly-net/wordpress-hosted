# wordpress-hosted

---

These instructions should be updated to reflect the current state of the project.

---

Template repository for Savantly Wordpress Enterprise hosting

Savantly provide a container based Wordpress hosting solution that is designed to be scalable, secure and easy to manage.  
This repository is a template for creating a custom Wordpress hosting solution that can be deployed to the Savantly platform.

Feel free to fork this repository and customize it to your needs.

Contact us at [Savantly](https://savantly.net) for more information.

## TLDR;

Start up the local development environment with the following command:

```
make dev
```

## Build/Publish

1. Clone the repository
2. Replace the `IMAGE_NAME` variable in the `Makefile` with your own value
3. Do `make push` to build and push the image to the repository

## Release Tagged Version

1. Do `make release` to create a new release tag and push it to the repository and increment the version number

## Download Pod Assets

1. Do `make download` to download the plugins and themes from the pod

## GitHub Actions

1. Enable GitHub Actions in the repository, by removing the `.` in the file names in the `.github/workflows` directory
2. Replace the variables in the GitHub Actions workflow file `.github/workflows/main.yml` with your own values
3. Replace the variables in the GitHub Actions workflow file `.github/workflows/release.yml` with your own values

# pause image for riscv64

The k8s snap starts every pod with a "pause" (sandbox) container. Its
default image is `ghcr.io/canonical/k8s-snap/pause:3.10`, which has no
riscv64 variant. This directory shows how to get a riscv64 pause image
into the snap in two ways:

* A. use the existing `docker.io/xypron/pause:3.10` (no build needed);
* B. build the image yourself and upload it to Docker Hub.

The image is one static C program (`pause.c`, from kubernetes
v1.37.1, `build/pause/linux/pause.c`, Apache-2.0) in an image with
entrypoint `/pause`, user 65535.

All commands run on the riscv64 machine, as a normal user unless
`sudo` is shown.

## A. Use the existing docker.io/xypron/pause:3.10

There are two ways. Pick one.

### A1. Tell containerd to use it (needs internet on the node)

1. Write a bootstrap file `bootstrap.yaml`:

       extra-node-containerd-config:
         plugins:
           io.containerd.grpc.v1.cri:
             sandbox_image: docker.io/xypron/pause:3.10

2. Bootstrap with it:

       sudo k8s bootstrap --file bootstrap.yaml

3. Every node that joins needs the same `extra-node-containerd-config`
   in its join file (`sudo k8s join-cluster <token> --file join.yaml`).
4. Check:

       sudo grep sandbox_image /etc/containerd/config.toml

   It must print `docker.io/xypron/pause:3.10`. If the line is
   missing, containerd 2.x may use another table name; look at the
   `sandbox` / `pinned_images` entry in the file and adapt the YAML.

### A2. Import it under the default name (works offline)

The snap then needs no configuration at all.

1. Install skopeo: `sudo apt install skopeo`.
2. Download the image and give it the name the snap expects:

       skopeo copy --override-arch riscv64 --override-os linux \
         docker://docker.io/xypron/pause:3.10 \
         docker-archive:pause.tar:ghcr.io/canonical/k8s-snap/pause:3.10

3. Import it into the snap's containerd. Do this on every node, before
   or after bootstrap, but before pods start:

       sudo /snap/k8s/current/bin/ctr \
         --address /run/containerd/containerd.sock \
         -n k8s.io images import pause.tar

   Copying the tar to `/var/snap/k8s/common/images` does NOT import it.
4. Check: `sudo /snap/k8s/current/bin/ctr --address
   /run/containerd/containerd.sock -n k8s.io images ls | grep pause`.

## B. Build the image yourself

No docker is needed. Required packages:

    sudo apt install gcc skopeo python3 tar

Build:

    ./build.sh

Result:

* `build/pause.tar`: a docker-archive tagged
  `ghcr.io/canonical/k8s-snap/pause:3.10`. Import it as in A2 step 3.
  To use another name: `./build.sh docker.io/<you>/pause:3.10`.
* `build/oci`: an OCI layout for uploading (below).

The script compiles `pause.c` with the flags of the kubernetes
Makefile (`-Os -Wall -Werror -static`), packs the binary as the only
layer and writes the image config (entrypoint `/pause`, user
65535:65535). The `build/` directory is not tracked by git.

Check that it works without a cluster:

    skopeo inspect --config oci:build/oci

## C. Upload the image to Docker Hub

You need a Docker Hub account (here `<you>`). The repository
`<you>/pause` is created by the first push.

1. Create an access token: Docker Hub, Account settings, Personal
   access tokens, permission "Read & Write".
2. Log in with skopeo (paste the token as password):

       skopeo login docker.io -u <you>

3. Push the image built in B. Push two tags, the second one makes it
   clear which architecture the image has:

       skopeo copy oci:build/oci docker://docker.io/<you>/pause:3.10
       skopeo copy oci:build/oci docker://docker.io/<you>/pause:3.10-linux-riscv64

   (`docker.io/xypron/pause` was published the same way: tags `3.10`
   and `3.10-linux-riscv64`, one riscv64 image.)
4. Check from another machine:

       skopeo inspect --override-arch riscv64 docker://docker.io/<you>/pause:3.10

5. Use it: follow A1 or A2 with `<you>` instead of `xypron`.

Notes:

* The image is single-arch. On amd64 or arm64 nodes this tag does not
  run; for a mixed cluster build a manifest list instead of using A1.
* Everybody who uses an image from a personal Docker Hub account must
  trust its owner. For upstream the image should be published as
  `ghcr.io/canonical/k8s-snap/pause:3.10` from the pause-rock
  repository (see PLAN.md 7.10).

## Files

| File | Purpose |
|---|---|
| `pause.c` | Source of the pause program (kubernetes v1.37.1) |
| `build.sh` | Builds `build/pause.tar` and `build/oci` without docker |
| `README.md` | This guide |

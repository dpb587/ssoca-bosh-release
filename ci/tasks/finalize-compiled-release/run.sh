#!/bin/bash

set -eu -o pipefail

task_dir=$PWD

release_name=$( bosh interpolate --path /final_name repo/config/final.yml )
s3_host=$( bosh interpolate --path /blobstore/options/host repo/config/final.yml )
s3_bucket=$( bosh interpolate --path /blobstore/options/bucket_name repo/config/final.yml )

git config --global user.email "${git_user_email:-ci@localhost}"
git config --global user.name "${git_user_name:-CI Bot}"
export GIT_COMMITTER_NAME="Concourse"
export GIT_COMMITTER_EMAIL="concourse.ci@localhost"

git clone --quiet file://$task_dir/repo updated-repo

tar -xzf compiled-release/*.tgz $( tar -tzf compiled-release/*.tgz | grep release.MF$ )
version=$( grep '^version:' release.MF | awk '{print $2}' | tr -d "\"'" )
stemcell=$( grep 'stemcell:' release.MF | head -n1 | awk '{print $2}' | tr -d "\"'" )
stemcell_os=$( echo "$stemcell" | cut -d/ -f1 )
stemcell_version=$( echo "$stemcell" | cut -d/ -f2 )

cd updated-repo/


#
# we'll upload to the blobstore
#

export AWS_ACCESS_KEY_ID="$blobstore_s3_access_key_id"
export AWS_SECRET_ACCESS_KEY="$blobstore_s3_secret_access_key"


#
# upload the compiled release tarball
#

tarball_real=$( echo "../compiled-release/$release_name"-*.tgz )
tarball_nice="$release_name-$version-on-$stemcell_os-stemcell-$stemcell_version"

metalink_path="releases/$release_name/$stemcell_os/$stemcell_version/$release_name-$version.meta4"

mkdir -p "$( dirname "$metalink_path" )"

meta4 create --metalink="$metalink_path"
meta4 set-published --metalink="$metalink_path" "$( date -u +%Y-%m-%dT%H:%M:%SZ )"
meta4 import-file --metalink="$metalink_path" --file="$tarball_nice" --version="$version" "$tarball_real"
meta4 file-upload --metalink="$metalink_path" --file="$tarball_nice" "$tarball_real" "s3://$s3_host/$s3_bucket/compiled_releases/$release_name/$( basename "$tarball_real" )"


#
# commit compiled release
#

git add -A compiled_releases

git commit -m "Finalize compiled release ($stemcell)"

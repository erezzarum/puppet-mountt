class mountt (
  $mounts          = {}
) {
  validate_hash($mounts)
  if ($mounts != {}) {
    create_resources('::mountt::mount', $mounts)
  }
}
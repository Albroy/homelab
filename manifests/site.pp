$role = $trusted['extensions']['pp_role']

node default {
  include "roles::${role}"
}

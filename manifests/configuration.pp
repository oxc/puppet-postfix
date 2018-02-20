# @api private
# This class handles postfix configuration. Avoid modifying private classes.
class postfix::configuration inherits postfix {
  each({
    'postconf' => $postfix::purge_main,
    'postconf_master' => $postfix::purge_master,
  }) |$res, $purge| {
    case $purge {
      true, 'true', 'noop': {
        resources { $res: purge => true, noop => $purge == 'noop' }
      }
    }
  }

  $postfix::main_config.each |$key, $value| {
    $_value = $value ? {
      true    => 'yes',
      false   => 'no',
      default => $value,
    }
    postconf { $key: value => $_value }
  }
  $postfix::master_services.each |$key, $args| {
    $_args = delete($args, [command, options])
    if $args[options] {
      $_command = $args[options].reduce($args[command]) |$c, $o| {
        $key = $o[0]
        $val = $o[1]
        $_val = $val ? {
          true    => 'yes',
          false   => 'no',
          default => $val,
        }
        $opt = $_val ? {
          / /     => "-o { ${key} = ${_val} }",
          default => "-o ${key}=${_val}",
        }
        "${c} ${opt}"
      }
    } else {
      $_command = $args[command]
    }
    postconf_master { $key:
      command => $_command,
      * => $_args,
    }
  }
}

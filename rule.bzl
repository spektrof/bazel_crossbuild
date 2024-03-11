
def _has_no_remote_tag(tags):
  no_remote_tags = ["no-remote", "no-remote-exec"]
  return not any([t in tags for t in no_remote_tags])

def _has_no_remote_tag_from_ctx(ctx):
  return _has_no_remote_tag(ctx.attr.tags)

def _target_platform_to_exec_group(ctx):
  target_platform = ctx.fragments.platform.platform
  return {
    "@//platform:rhel7" : "rhel7",
    "@//platform:rhel8" : "rhel8",
  }.get(str(target_platform), None)

def _intermediate_action_impl(ctx):
  intermediate_executable_name = ".bin/{}".format(ctx.attr.name)
  intermediate_executable = ctx.actions.declare_file(intermediate_executable_name)
 
  exec_group = _target_platform_to_exec_group(ctx) if _has_no_remote_tag_from_ctx(ctx) else "host"

  print("{} rule uses {} files, {} tags, {} exec_group ".format(ctx.attr.name, ctx.files.tool, ctx.attr.tags, exec_group))

  ctx.actions.run(
    inputs = [],
    outputs = [intermediate_executable],
    executable = ctx.executable.tool,
    arguments = [intermediate_executable.path],
    mnemonic = "InterAction",
    progress_message = "Run intermediate action for {}".format(ctx.attr.name),
    execution_requirements = {tag : '1' for tag in ctx.attr.tags},
    exec_group = exec_group,
  )

  return DefaultInfo(
    files = depset([intermediate_executable]),
    executable = intermediate_executable
  )


def _create_intermediate_action_rule(cfg="exec"):
  return rule(
    implementation = _intermediate_action_impl,
    attrs = {
      "tool" : attr.label(
        mandatory=True,
        executable=True,
        cfg="exec",
      ),
    },
    exec_groups = {
      "host" :  exec_group(exec_compatible_with=["@crossbuild//constraint:host"]),
      "rhel7" : exec_group(exec_compatible_with=["@crossbuild//constraint:rhel7"]),
      "rhel8" : exec_group(exec_compatible_with=["@crossbuild//constraint:rhel8"]),
    },
    fragments = ["platform"],
  )

intermediate_action = _create_intermediate_action_rule()

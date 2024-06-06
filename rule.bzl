
def _has_no_remote_tag(ctx):
  no_remote_tags = ["no-remote", "no-remote-exec"]
  return any([t in ctx.attr.tags for t in no_remote_tags])

def _target_platform_to_exec_group(ctx):
  target_platform = ctx.fragments.platform.platform
  return {
    "@//platform:rhel7" : "rhel7",
    "@//platform:rhel8" : "rhel8",
  }.get(str(target_platform), None)

def _intermediate_action_impl(ctx):
  intermediate_executable_name = ".bin/{}".format(ctx.attr.name)
  intermediate_executable = ctx.actions.declare_file(intermediate_executable_name)
 
  # check https://bazel.build/extending/auto-exec-groups whenever Bazel7+ is used
  # exec_group = "host" if _has_no_remote_tag(ctx) else _target_platform_to_exec_group(ctx)

  print("{} rule uses {} files, {} tags".format(ctx.attr.name, ctx.files.tool, ctx.attr.tags))

  ctx.actions.run(
    inputs = [],
    outputs = [intermediate_executable],
    executable = ctx.executable.tool,
    arguments = [intermediate_executable.path],
    mnemonic = "InterAction",
    progress_message = "Run intermediate action for {}".format(ctx.attr.name),
    execution_requirements = {tag : '1' for tag in ctx.attr.tags},
    # exec_group = exec_group,
  )

  # C++ actions are using rhel8 toolchain
  # TODO: add analysis tests instead

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
        cfg=cfg,
      ),
    },
    # see https://bazel.build/extending/auto-exec-groups
    # exec_groups = {
    #   "host" :  exec_group(exec_compatible_with=["@crossbuild//constraint:host_platform"]),
    #   "rhel7" : exec_group(exec_compatible_with=["@crossbuild//constraint:rhel7"]),
    #   "rhel8" : exec_group(exec_compatible_with=["@crossbuild//constraint:rhel8"]),
    # },
    fragments = ["platform"],
  )

intermediate_action = _create_intermediate_action_rule()

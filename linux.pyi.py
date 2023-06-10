"""
函数文档来自 https://rawgit.com/Fewbytes/rubber-docker/master/docs/linux/index.html
"""
import typing as t


def clone(callback: t.Callable, flags: int, callback_args: t.Tuple):
    """
    create a child process

    Args:
        callback: (Callable) – python function to be executed by the forked child
        flags: (int) – combination (using |) of flags specifying what should be shared between the calling process and the child process. See below.
        callback_args: (tuple) – tuple of arguments for the callback function

    Returns: On success, the thread ID of the child process

    Raises: RuntimeError – if clone fails

    Useful flags:

        linux.CLONE_NEWNS - Unshare the mount namespace

        linux.CLONE_NEWUTS - Unshare the UTS namespace (hostname, domainname, etc)

        linux.CLONE_NEWNET - Unshare the network namespace

        linux.CLONE_NEWPID - Unshare the PID namespace

    """
    ...

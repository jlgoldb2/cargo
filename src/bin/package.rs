use cargo::ops;
use cargo::core::{MultiShell};
use cargo::util::{CliResult, CliError};
use cargo::util::important_paths::find_root_manifest_for_cwd;

#[deriving(Decodable)]
struct Options {
    flag_verbose: bool,
    flag_manifest_path: Option<String>,
    flag_no_verify: bool,
    flag_no_metadata: bool,
    flag_list: bool,
}

pub const USAGE: &'static str = "
Assemble a the local package into a distributable tarball

Usage:
    cargo package [options]

Options:
    -h, --help              Print this message
    -l, --list              Print files included in a package without making one
    --no-verify             Don't verify the contents by building them
    --no-metadata           Ignore warnings about a lack of human-usable metadata
    --manifest-path PATH    Path to the manifest to compile
    -v, --verbose           Use verbose output

";

pub fn execute(options: Options, shell: &mut MultiShell) -> CliResult<Option<()>> {
    shell.set_verbose(options.flag_verbose);
    let root = try!(find_root_manifest_for_cwd(options.flag_manifest_path));
    ops::package(&root, shell,
                 !options.flag_no_verify,
                 options.flag_list,
                 !options.flag_no_metadata).map(|_| None).map_err(|err| {
        CliError::from_boxed(err, 101)
    })
}

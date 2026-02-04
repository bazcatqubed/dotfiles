# Like `glob` built-in except it lists paths relative to the current directory.
export def glob-relative --env [glob: string] {
  glob $glob | path relative-to $env.PWD
}

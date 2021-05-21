require "yaml"

libs = [
  "lib/json.pas",
  "lib/utils.pas",
  "lib/types.pas"
]

dep_map = {
  "bin/json_tester"  => ["test/json_tester.pas"  , *libs],
  "bin/utils_tester" => ["test/utils_tester.pas" , *libs],
  "bin/lexer"   => ["lexer.pas"  , *libs],
  "bin/parser"  => ["parser.pas" , *libs],
  "bin/codegen" => ["codegen.pas", *libs],
}

dep_map.each do |goal, src_files|
  file goal => src_files do |t|
    exe_file = t.name
    src_file = src_files[0]

    cmd = [
      %(docker run --rm -v "$(pwd):/root/work"),
      %(  my:free-pascal),
      %(fpc -o"#{exe_file}"),
      %(  -Sh -Fu"./lib"),
      %(  "#{src_file}"),
    ].join(" ")

    sh cmd
  end
end

task :default => :"build-all"
task :"build-all" => dep_map.keys

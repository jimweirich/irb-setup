if RUBY_VERSION >= "1.9"
  require 'ripper'
  require 'pp'

  def parse(string)
    sexp = Ripper::SexpBuilder.new(string).parse
    sexp = sexp[1] if sexp.first == :program
    sexp = sexp[2] if sexp.first == :stmts_add
    pp sexp
    nil
  end
end

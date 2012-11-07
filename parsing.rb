if RUBY_VERSION >= "1.9"
  begin
    require 'ripper'
  rescue LoadError => ex
  end

  if defined?(Ripper)
    require 'pp'

    def parse(string)
      sexp = Ripper::SexpBuilder.new(string).parse
      sexp = sexp[1] if sexp.first == :program
      sexp = sexp[2] if sexp.first == :stmts_add
      pp sexp
      nil
    end
  end
end

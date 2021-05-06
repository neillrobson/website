require 'kramdown/parser/kramdown'

class Kramdown::Parser::NeillKramdown < Kramdown::Parser::Kramdown

    def initialize(source, options)
        super
        @block_parsers.unshift(:layout_tag)
    end

    LAYOUT_TAG = /^#{OPT_SPACE}\{([<>\|]{1,2})\} ?/

    CLASSES = {
        '<<' => 'wide left',
        '>>' => 'wide right',
        '<>' => 'wide',
        '<' => 'inside left',
        '>' => 'inside right',
        '|<' => 'margin left',
        '>|' => 'margin right'
    }

    # Note that @src is a Kramdown StringScanner, which is just a Ruby
    # StringScanner augmented with line number information.
    def parse_layout_tag
        if @src.check(LAYOUT_TAG)
            div_class = CLASSES[@src[1]]
            if div_class == nil
                return false
            end

            start_line_number = @src.current_line_number
            result = @src.scan(PARAGRAPH_MATCH)
            until @src.match?(self.class::LAZY_END)
                result << @src.scan(PARAGRAPH_MATCH)
            end
            result.gsub!(LAYOUT_TAG, '')

            el = new_block_el(:html_element, 'div', { :class => div_class }, category: :block, location: start_line_number)
            @tree.children << el
            parse_blocks(el, result)
            true
        else
            false
        end
    end
    define_parser(:layout_tag, LAYOUT_TAG)

end

class Jekyll::Converters::Markdown::NeillKramdown
    def initialize(config)
        require 'kramdown'
        @config = config
    rescue LoadError
        STDERR.puts 'You are missing a library required for Markdown. Please run:'
        STDERR.puts '  $ [sudo] gem install kramdown'
        raise FatalException.new("Missing dependency: kramdown")
    end

    def convert(content)
        Kramdown::Document.new(content, :input => 'NeillKramdown').to_html
    end
end

# Helper for executing shell commands
module ProcessHelper
  def valid_option_pairs
    [
      [
        :expected_exit_status,
        :exp_rc,
      ],
      [
        :include_output_in_exception,
        :out_ex,
      ],
      [
        :puts_output,
        :out,
      ],
      [
        :puts_output_only_on_exception,
        :out_only_on_ex,
      ],
    ]
  end

  def valid_options
    valid_option_pairs.flatten
  end

  def validate_long_vs_short_option_uniqueness(options)
    invalid_options = (options.keys - valid_options)
    fail "Invalid option(s) '#{invalid_options.join(', ')}' given.  " \
          "Valid options are: #{valid_options.join(', ')}" unless invalid_options.empty?
    valid_option_pairs.each do |pair|
      long_option_name, short_option_name = pair
      if options[long_option_name] && options[short_option_name]
        fail "Cannot specify both '#{long_option_name}' and '#{short_option_name}'"
      end
    end
  end

  def convert_short_options(options)
    valid_option_pairs.each do |pair|
      long, short = pair
      options[long] = options.delete(short) unless options[short].nil?
    end
  end

  def validate_option_values(options)
    options.each do |option, value|
      valid_option_pairs.each do |pair|
        long_option_name, _ = pair
        next unless option == long_option_name
        validate_integer(pair, value) if option.to_s =~ /exit_status/
        validate_boolean(pair, value) if option.to_s =~ /output/
      end
    end
  end

  def validate_integer(pair, value)
    fail "#{pair.join(',')} options must be an Integer" unless value.is_a?(Integer)
  end

  def validate_boolean(pair, value)
    fail "#{pair.join(',')} options must be an Integer" unless value == true || value == false
  end

  def ensure_output_is_shown_on_error(options)
    return unless options[:puts_output] == false
    options[:puts_output_only_on_exception] = true if options[:puts_output_only_on_exception].nil?
    return if options[:puts_output_only_on_exception] == true
    if options[:include_output_in_exception] == false
      err_msg = 'WARNING: Check your ProcessHelper options - ' \
        'output will be suppressed if process fails.'
    else
      err_msg = 'WARNING: Check your ProcessHelper options - ' \
        'output will be suppressed unless process ' \
        "fails with an exit code other than #{options[:expected_exit_status]}."
    end
    $stderr.puts(err_msg)
  end

  def get_output(stdout_and_stderr)
    output = ''
    while (line = stdout_and_stderr.gets)
      output += line
    end
    output
  end

  def handle_exit_status(cmd, options, output, wait_thr)
    expected_exit_status = options[:expected_exit_status] || 0
    exit_status = wait_thr.value
    return if exit_status.exitstatus == expected_exit_status
    exit_status_msg =
      if expected_exit_status == 0
        ''
      else
        " (expected #{expected_exit_status})"
      end

    exception_message = "Command failed, #{exit_status}#{exit_status_msg}. " \
    "Command: `#{cmd}`."
    if options[:include_output_in_exception]
      exception_message += " Command Output: \"#{output}\""
    end
    puts output if options[:puts_output_only_on_exception] == true
    fail exception_message
  end

  def process(cmd, options = {})
    options = options.dup
    validate_long_vs_short_option_uniqueness(options)
    convert_short_options(options)
    validate_option_values(options)
    ensure_output_is_shown_on_error(options)
    Open3.popen2e(cmd) do |_, stdout_and_stderr, wait_thr|
      output = get_output(stdout_and_stderr)
      puts output unless options[:puts_output] == false

      handle_exit_status(cmd, options, output, wait_thr)
      output
    end
  end

  alias_method :run, :process
end

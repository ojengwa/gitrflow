require_relative 'spec_helper'

describe 'options' do
  describe 'fails if' do
    it 'unprocessed parameters exist' do
      local_repo, _ = make_cloned_repo
      FileUtils.cd(local_repo) do
        cmd = gitrflow_cmd('feature start feature1 unprocessed')
        out = run(cmd, out: false, exp_rc: 1)
        expect(out).to match(/ERROR: Unrecognized parameter 'unprocessed'/)
      end
    end

    it 'invalid options exist' do
      out = run(gitrflow_cmd('--invalid'), out: false, exp_rc: 1)
      expect(out).to match(/ERROR: Unrecognized parameter '--invalid'/)
    end
  end

  describe 'behavior' do
    it 'prints help if no options are passed' do
      expect(
        run(gitrflow_cmd, out: false, exp_rc: 1)
      ).to match(/Usage:/m)
    end

    it 'processes options after commands' do
      out = run(gitrflow_cmd('feature start feature1 --version'), out: false)
      expect(out).to match(version_regex)
    end
  end

  it '-h, --help' do
    expect(run(gitrflow_script('--help'), out: false, exp_rc: 1)).to match(/^Usage:/)
    out = run(gitrflow_script('-h'), out: false, exp_rc: 1)
    expect(out).to match(/^Usage:/)
    expect(out).to match(/^    -h, --help                  Display this \[h\]elp/)
  end

  describe '-c, --print-git-commands' do
    it 'has help text' do
      help_out = run(gitrflow_script('-h'), out: false, exp_rc: 1)
      expected_help_out = /^    -c, --print-git-commands    Print git \[c\]ommands as they are run/
      expect(help_out).to match(expected_help_out)
    end

    it 'when fail_unless_repo_clean has git output' do
      local_repo, _ = make_cloned_repo

      expected_out = init_defaults_output('-c') +
        "git status --porcelain\n" \
        "ERROR: Local repo is not clean. Please fix and retry.\n" \
        "'git-rflow --help' for usage.\n"

      FileUtils.cd(local_repo) do
        FileUtils.touch('dirty')
        cmd = gitrflow_cmd('-c feature start feature1')
        out = run(cmd, out: false, exp_rc: 1)
        expect(out).to eq(expected_out)
      end
    end
  end

  describe '-d, --debug' do
    it 'has help text' do
      help_out = run(gitrflow_script('-h'), out: false, exp_rc: 1)
      expected_help_out =
        /^    -d, --debug                 Debug git-rflow script with bash xtrace/
      expect(help_out).to match(expected_help_out)
    end

    it 'turns on GITRFLOW_BASH_XTRACE' do
      cmd = gitrflow_cmd('-d -h')
      out = run(cmd, out: false, exp_rc: 1)
      expect(out).to match(/\+\(.*git-rflow:\d+\): print_usage_and_exit\(\): printf 'Usage:\\n'/)
      expect(out).to match(/^Usage:\n/)
    end
  end

  describe '-o, --print-git-output' do
    it 'has help text' do
      help_out = run(gitrflow_script('-h'), out: false, exp_rc: 1)
      expected_help_out = /^    -o, --print-git-output      Print \[o\]utput from git commands/
      expect(help_out).to match(expected_help_out)
    end

    it 'when fail_unless_repo_clean has git output' do
      local_repo, _ = make_cloned_repo

      expected_out = init_defaults_output('-o') +
        "?? dirty\n" \
        "ERROR: Local repo is not clean. Please fix and retry.\n" \
        "'git-rflow --help' for usage.\n"

      FileUtils.cd(local_repo) do
        FileUtils.touch('dirty')
        cmd = gitrflow_cmd('-o feature start feature1')
        out = run(cmd, out: false, exp_rc: 1)
        expect(out).to eq(expected_out)
      end
    end

    it 'when fail_if_unpushed_changes and feature_start have git output' do
      local_repo, _ = make_cloned_repo
      branch = 'feature1'

      expected_out = init_defaults_output('-o') +
        git_version_status_porcelain_branch_output +
        "\n" \
        "Switched to a new branch '#{branch}'\n" \
        "\n" \
        "Summary of actions:\n" \
        "- A new branch '#{branch}' was created, based on 'master'\n" \
        "- You are now on branch '#{branch}'\n\n" \
        "Now, start committing on your feature. When done, use:\n\n" \
        "     git flow feature finish #{branch}\n"

      FileUtils.cd(local_repo) do
        out = run(gitrflow_cmd("--print-git-output feature start #{branch}"), out: false)
        expect(out).to eq(expected_out)
      end
    end
  end

  describe '--version' do
    it 'has help text' do
      expect(
        run(gitrflow_cmd('-h'), out: false, exp_rc: 1)
      ).to match(/^    -V, --version               Display the program \[v\]ersion/m)
    end

    it 'shows version' do
      expect(run(gitrflow_cmd('--version'), out: false)).to match(version_regex)
      out = run(gitrflow_cmd('-V'), out: false)
      expect(out).to match(version_regex)
    end
  end

  describe 'option combinations' do
    it '--print-git-commands and --print-git-output together' do
      local_repo, _ = make_cloned_repo
      branch = 'feature1'

      expected_out = init_defaults_output('-c -o') +
        "git status --porcelain\n" \
        "git status --porcelain --branch\n" +
        git_version_status_porcelain_branch_output +
        "\n" \
        "git checkout -b feature1\n" \
        "Switched to a new branch '#{branch}'\n" \
        "\n" \
        "Summary of actions:\n" \
        "- A new branch '#{branch}' was created, based on 'master'\n" \
        "- You are now on branch '#{branch}'\n\n" \
        "Now, start committing on your feature. When done, use:\n\n" \
        "     git flow feature finish #{branch}\n"

      FileUtils.cd(local_repo) do
        out = run(gitrflow_cmd("-c -o feature start #{branch}"), out: false)
        expect(out).to eq(expected_out)
      end
    end
  end

  it 'ignores all options after --' do
    expect(
      run(gitrflow_cmd('-- --version'), out: false, exp_rc: 1)
    ).to match(/^    --                          Ignore all following options/m)
  end

  def version_regex
    /^git-rflow, version \d\.\d\.\d/
  end
end

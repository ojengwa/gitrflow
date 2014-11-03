require_relative 'spec_helper'

describe 'branch type parameter' do
  it 'fails if no command is specified' do
    out = run("#{gitrflow_cmd} feature", out: false, exp_rc: 1)
    expect(out).to match(/ERROR: The feature branch command is required./)
    expect(out).to match(/'git rflow --help' for usage./)
  end
end

describe 'start' do
  describe 'fails if' do
    it 'no branch name is specified' do
      out = run("#{gitrflow_cmd} feature start", out: false, exp_rc: 1)
      expect(out).to match(/ERROR: The feature branch name is required./)
      expect(out).to match(/'git rflow --help' for usage./)
    end

    it 'local repo is not clean' do
      local_repo, _ = make_cloned_repo
      FileUtils.cd(local_repo) do
        FileUtils.touch('dirty')
        cmd = "#{gitrflow_cmd} feature start feature1"
        out = run(cmd, out: false, out_only_on_ex: true, exp_rc: 1)
        expect(out).to match(/ERROR: Local repo is not clean. Please fix and retry./)
      end
    end

    it 'local repo is "gone"' do
      local_repo, _ = make_cloned_repo([])
      FileUtils.cd(local_repo) do
        FileUtils.touch('unpushed')
        run('git add unpushed && git ci -m "unpushed"', out: false, out_only_on_ex: true)
        cmd = "#{gitrflow_cmd} feature start feature1"
        out = run(cmd, out: false, out_only_on_ex: true, exp_rc: 1)
        expect(out).to match(/ERROR: Local repo is "gone". Please fix and retry./)
      end
    end

    it 'local repo has unpushed changes' do
      local_repo, _ = make_cloned_repo
      FileUtils.cd(local_repo) do
        FileUtils.touch('unpushed')
        run('git add unpushed && git ci -m "unpushed"', out: false, out_only_on_ex: true)
        cmd = "#{gitrflow_cmd} feature start feature1"
        out = run(cmd, out: false, out_only_on_ex: true, exp_rc: 1)
        expect(out).to match(/ERROR: Local repo has unpushed changes. Please fix and retry./)
      end
    end
  end

  it 'creates the specified feature branch' do
    local_repo, _ = make_cloned_repo
    branch = 'feature1'
    expected_out = "Switched to a new branch '#{branch}'\n\n" \
    "Summary of actions:\n" \
    "- A new branch '#{branch}' was created, based on 'master'\n" \
    "- You are now on branch '#{branch}'\n\n" \
    "Now, start committing on your feature. When done, use:\n\n" \
    "     git flow feature finish #{branch}"

    FileUtils.cd(local_repo) do
      cmd = "#{gitrflow_cmd} feature start #{branch}"
      out = run(cmd, out: false, out_only_on_ex: true)
      expect(out).to eq(expected_out)
      git_status = run('git status', out: false, out_only_on_ex: true)
      expect(git_status).to match(/On branch #{branch}/)
    end
  end
end

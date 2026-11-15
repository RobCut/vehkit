function plan = buildfile
%BUILDFILE Build tasks for vehkit.
%   buildtool reads this file automatically from the repository root.
%   Available tasks:
%    test - run the full test suite (default)

plan = buildplan(localfunctions);
plan.DefaultTasks = "test";
end

function testTask(context) %#ok<INUSD>
%testTask Run the full test suite.

results = runtests('tests');
assertSuccess(results);
end
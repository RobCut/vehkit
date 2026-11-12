function out = replaceEmptyWithNaN(in)
%replaceEmptyWithNaN Replace empty numeric arrays with NaN recursively.
%   OUT = replaceEmptyWithNaN(IN) traverses IN and replaces any empty
%   numeric array with the scalar NaN. Structs and cell arrays are
%   traversed recursively. Non-empty values are returned unchanged.

if isnumeric(in) && isempty(in)
    out = NaN;
elseif isstruct(in)
    out = in;
    for k = 1:numel(in)
        fields = fieldnames(in);
        for f = 1:numel(fields)
            name = fields{f};
            out(k).(name) = vehkit.internal.replaceEmptyWithNaN(in(k).(name));
        end
    end
elseif iscell(in)
    out = cell(size(in));
    for k = 1:numel(in)
        out{k} = vehkit.internal.replaceEmptyWithNaN(in{k});
    end
else
    out = in;
end
end
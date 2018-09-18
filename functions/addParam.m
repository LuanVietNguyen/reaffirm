function  param = addParam(chart, name)
    %  create local, output, and input variables in SLSF model
    param = addVariable(chart, name, 'Parameter');
    param.DataType = 'double';
end
# parse arguments
#   'blogin post -ac -b testname date'
#     =>
#   {opt: ['ac', 'b'], req: ['testname', 'date']}
exports.parse = (args) ->
  opt = [] # option arguments, like  => ['ac', 'b']
  req = [] # required arguments
  args.forEach (value) =>
    if value[0] is '-'
      opt.push(value.slice(1))
    else
      req.push(value)

  return {
    opt: opt
    req: req
  }
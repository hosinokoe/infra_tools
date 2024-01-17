def later($n; $unit):
  def dict: { YEAR:0, MONTH:1, DAY:2, HOUR:3, MINUTE:4, SECOND:5, MIN:4, SEC:5};
  gmtime
  | .[dict[$unit]] += $n
  | mktime ;
#27/01/10
# First Ruby script ever.

def insertion_sort(a)
  a = a.dup
  lim = 0
  (a.length - 1).times do
    nxt = lim + 1
    a[0..lim].each do |n|
      if block_given?
        test = yield(a[nxt], n)
      else
        test = n > a[nxt]
      end
      if test
        nxt = a.index n
        break
      end
    end
    if nxt != lim + 1
      a[nxt, 0] = a[lim + 1]
      a.delete_at lim + 2
    end
    lim += 1
  end
  a
end

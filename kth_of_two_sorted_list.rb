class KthOfTwoSorted
  def kth_of_two_sorted(k, arrx, arry)
    (arrx.size+arry.size).tap do |len|
      raise ArgumentError,"k should in range #{0..len}" unless 0<=k && k<len
    end

    arrx,arry = [arrx,arry].sort_by(&:size)
    if arrx.size < k
      arry.shift(k-arrx.size)
      k = arrx.size
    end

    safe_kth(k, arrx, arry)
  end

  private
  def safe_kth(k, arrx, arry)
    return [arrx.first,arry.first].compact.min if k==0

    xmid = k/2
    ymid = k-(xmid+1)
    if arrx[xmid] <= arry[ymid]
      safe_kth(k-xmid-1, shift(arrx,xmid+1), arry)
    else
      safe_kth(k-ymid-1, arrx, shift(arry, ymid+1))
    end
  end

  def shift(arr, n); arr.shift(n);arr end
end


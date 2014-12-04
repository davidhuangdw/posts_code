y = ->(f){->(x){x[x]}[->(x){f[->(g){x[x][g]}]}]}    # proc[x] === proc.call(x)

_fact = ->(f){->(n){n==0?1:n*f[n-1]} }
fact = y[_fact]

puts (1..10).map(&fact)

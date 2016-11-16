GCD(a, b) {
   while b
      b := Mod(a | 0x0, a := b)
   return a
}

Between(i, a, b) {
   return (a < i && i < b)
}

Between2(i, a, b) {
   return (a <= i && i <= b)
}

Union(p1, p2, q1, q2) {
   p_min := (p1 > p2) ? p2 : p1
   p_max := (p1 > p2) ? p1 : p2
   q_min := (q1 > q2) ? q2 : q1
   q_max := (q1 > q2) ? q1 : q2
   return Between(q1, p_min, p_max) || Between(q2, p_min, p_max) || Between(p1, q_min, q_max) || Between(p2, q_min, q_max)
}
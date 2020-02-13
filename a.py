
def test(l, c=0):
    l.append(c)
    if c < 2:
        test(l, c+1)
    return l

l = []
print(test(l))

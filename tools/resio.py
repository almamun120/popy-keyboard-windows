import struct
def read_res(path):
    d=open(path,'rb').read(); p=0; out=[]
    while p<len(d):
        ds,hs=struct.unpack('<II',d[p:p+8]); q=p+8
        def rn(q):
            if struct.unpack('<H',d[q:q+2])[0]==0xFFFF: return struct.unpack('<H',d[q+2:q+4])[0],q+4
            e=q
            while d[e:e+2]!=b'\0\0': e+=2
            return d[q:e].decode('utf-16le'),e+2
        t,q=rn(q); n,q=rn(q)
        if q%4: q+=4-q%4
        dv,mf,lang,ver,ch=struct.unpack('<IHHII',d[q:q+16])
        data=d[p+hs:p+hs+ds]; out.append((t,n,mf,lang,data))
        p=p+hs+ds; p+=(4-p%4)%4
    return out
def write_res(entries):
    out=b'\x00\x00\x00\x00\x20\x00\x00\x00\xff\xff\x00\x00\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
    def nm(v): return struct.pack('<HH',0xFFFF,v) if isinstance(v,int) else v.upper().encode('utf-16le')+b'\0\0'
    for t,n,mf,lang,data in entries:
        h=nm(t)+nm(n)
        if len(h)%4: h+=b'\0'*(4-len(h)%4)
        h+=struct.pack('<IHHII',0,mf,lang,0,0)
        hs=8+len(h)
        out+=struct.pack('<II',len(data),hs)+h+data
        out+=b'\0'*((4-len(out)%4)%4)
    return out

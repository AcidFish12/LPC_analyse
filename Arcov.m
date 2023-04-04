function lpc_coffer=Arcov(x,p)
N=length(x);

for i=1:p
    for j=0:p
        if (i>j)
            M=N-i+j;
            L=1+i-j;
            c(i,j+1)=sum(x(1:N-i+j).*x(1+i-j:N));
        else
            c(i,j+1)=sum(x(1:N+i-j).*x(1-i+j:N));
        end
    end
end
C0=c(:,1);
C=c(:,2:p+1);
a=C\C0;
for i=1:p
    lpc_coffer(i+1)=-a(i);
end

lpc_coffer(1)=1;

end

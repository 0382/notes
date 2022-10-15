using OffsetArrays
const N = 100

function case_1()
    # 挖掉部分 [L/3, 2L/3] × [L/3, 2L/3]
    # julia 从 1 开始的索引在这里确实难受，用 `OffsetArrays` 包装一下
    ϕ0 = OffsetArray(zeros(3N+1, 3N+1), 0:3N, 0:3N)
    δϕ = copy(ϕ0)

    # 初值设为没有挖掉时的电势分布，便于更快收敛
    for i = 0:3N
        @. ϕ0[i, :] = 1 - i/3N
    end
    ϕ1 = copy(ϕ0)

    max_diff = 1.
    iter_num = 0
    while max_diff > 1e-10
        for j = 1:3N-1
            for i = 1:3N-1
                N <= i <= 2N && N <= j <= 2N && continue # 挖掉的部分
                @inbounds ϕ1[i,j] = (ϕ0[i-1,j]+ϕ0[i+1,j]+ϕ0[i,j-1]+ϕ0[i,j+1])/4
            end
        end
        # 处理边界条件
        for i = 1:3N-1
            # y = 0 处
            @inbounds ϕ1[i, 0] = (ϕ0[i-1,0]+ϕ0[i+1,0]+2ϕ0[i,1])/4
            # y = L 处
            @inbounds ϕ1[i, 3N] = (ϕ0[i-1,3N]+ϕ0[i+1,3N]+2ϕ0[i,3N-1])/4
        end
        # 处理挖掉部分的边界条件
        for i = (N+1):(2N-1)
            # y = L/3
            @inbounds ϕ1[i, N] = (ϕ0[i-1,N]+ϕ0[i+1,N]+2ϕ0[i,N-1])/4
            # y = 2L/3
            @inbounds ϕ1[i, 2N] = (ϕ0[i-1,2N]+ϕ0[i+1,2N]+2ϕ0[i,2N+1])/4
        end
        for j = (N+1):(2N-1)
            # x = L/3
            @inbounds ϕ1[N, j] = (ϕ0[N,j-1]+ϕ0[N,j+1]+2ϕ0[N-1,j])/4
            # x = 2L/3
            @inbounds ϕ1[2N, j] = (ϕ0[2N,j-1]+ϕ0[2N,j+1]+2ϕ0[2N+1,j])/4
        end
        # 内部的四个顶点
        ϕ1[N,N] = (ϕ0[N-1,N]+ϕ0[N+1,N]+ϕ0[N,N-1]+ϕ0[N,N+1])/4
        ϕ1[N,2N] = (ϕ0[N-1,2N]+ϕ0[N+1,2N]+ϕ0[N,2N-1]+ϕ0[N,2N+1])/4
        ϕ1[2N,N] = (ϕ0[2N-1,N]+ϕ0[2N+1,N]+ϕ0[2N,N-1]+ϕ0[2N,N+1])/4
        ϕ1[2N,2N] = (ϕ0[2N-1,2N]+ϕ0[2N+1,2N]+ϕ0[2N,2N-1]+ϕ0[2N,2N+1])/4
        @. δϕ = abs(ϕ1 - ϕ0)
        max_diff = maximum(δϕ)
        ϕ0, ϕ1 = ϕ1, ϕ0
        iter_num += 1
    end
    println("Jabobi algorithm converge after $iter_num iterations")
    E = @. 3N * (ϕ0[0, :] - ϕ0[1, :])
    # 令 σ = 1, 则 j = E
    I = sum(E[1:3N]) / 3N
    R = 1 / I
    return R
end

function case_2()
    # 挖掉部分 [L/3, 2L/3] × [0, L/3]
    ϕ0 = OffsetArray(zeros(3N+1, 3N+1), 0:3N, 0:3N)
    δϕ = copy(ϕ0)

    # 初值设为没有挖掉时的电势分布，便于更快收敛
    for i = 0:3N
        @. ϕ0[i, :] = 1 - i/3N
    end
    ϕ1 = copy(ϕ0)

    max_diff = 1.
    iter_num = 0
    while max_diff > 1e-10
        for j = 1:3N-1
            for i = 1:3N-1
                N <= i <= 2N && 0 <= j <= N && continue # 挖掉的部分
                @inbounds ϕ1[i,j] = (ϕ0[i-1,j]+ϕ0[i+1,j]+ϕ0[i,j-1]+ϕ0[i,j+1])/4
            end
        end
        # 处理边界条件
        for i = 1:3N-1
            # y = 0 处
            @inbounds ϕ1[i, 0] = (ϕ0[i-1,0]+ϕ0[i+1,0]+2ϕ0[i,1])/4
            # y = L 处
            N <= i <= 2N && continue # 边界也被挖掉了部分
            @inbounds ϕ1[i, 3N] = (ϕ0[i-1,3N]+ϕ0[i+1,3N]+2ϕ0[i,3N-1])/4
        end
        # 处理挖掉部分的边界条件
        for i = (N+1):(2N-1)
            # y = L/3
            @inbounds ϕ1[i, N] = (ϕ0[i-1,N]+ϕ0[i+1,N]+2ϕ0[i,N+1])/4
        end
        for j = 1:(N-1)
            # x = L/3
            @inbounds ϕ1[N, j] = (ϕ0[N,j-1]+ϕ0[N,j+1]+2ϕ0[N-1,j])/4
            # x = 2L/3
            @inbounds ϕ1[2N, j] = (ϕ0[2N,j-1]+ϕ0[2N,j+1]+2ϕ0[2N+1,j])/4
        end
        # 挖掉部分的四个顶点
        ϕ1[N,0] = (ϕ0[N-1,0]+ϕ0[N,1])/2
        ϕ1[2N,0] = (ϕ0[2N+1,0]+ϕ0[2N,1])/2
        ϕ1[N,N] = (ϕ0[N-1,N]+ϕ0[N+1,N]+ϕ0[N,N-1]+ϕ0[N,N+1])/4
        ϕ1[2N,N] = (ϕ0[2N-1,N]+ϕ0[2N+1,N]+ϕ0[2N,N-1]+ϕ0[2N,N+1])/4
        @. δϕ = abs(ϕ1 - ϕ0)
        max_diff = maximum(δϕ)
        ϕ0, ϕ1 = ϕ1, ϕ0
        iter_num += 1
    end
    println("Jabobi algorithm converge after $iter_num iterations")
    E = @. 3N * (ϕ0[0, :] - ϕ0[1, :])
    # 令 σ = 1, 则 j = E
    I = sum(E[1:3N]) / 3N
    R = 1 / I
    return R
end

function main()
    println(case_1())
    println(case_2())
end
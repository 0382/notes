# 精确对角化：01-Lanczos算法

通常而言，哈密顿量是厄米的，Lanczos算法是计算厄米矩阵部分本征值非常有效的算法。

> 注意下面所有的实对称性都可以替换为厄米性，与此同时正交替换为幺正。

## 幂法

假设矩阵$A$可以对角化，已知$A$的所有特征值$\lambda_i$和特征向量$v_i$（已正交归一），则$A$可以写成
$$
A = \sum_{i} \lambda_i v_i v_i^T
$$
对任意向量
$$
x = \sum_{i} c_i v_i
$$
将$A$不断地作用在这个向量上，就得到
$$
A^m x = \sum_{i}\lambda_i^m c_i v_i
$$
其中绝对值最大的特征值$\lambda_{max}$占的比例会越来越大。

如果构建
$$
q_k = \dfrac{A^k x}{||A^k x||}
$$
则有
$$
\lim_{k\to\infty} q_k^T A q_k = \lambda_{max}
$$
这就构成了一个很简单的迭代求解最大特征值的方法：幂法。不过幂法只能计算绝对值最大的特征值，且收敛速度并不快。

## Lanczos算法

Lanczos方法通过将矩阵$A$投影在Krylov子空间内，获得了比幂法更快的收敛速度。即任取一个向量$v$，所谓Krylov子空间即
$$
\mathcal{K}_m(A;v) = \mathrm{span}\{v, Av, \dots, A^{m-1} v\}
$$
可以看到幂法相当于仅仅是在$A^kv$子空间内求解特征值，而Lanczos方法将迭代过程中的其他向量也加进来，加快了收敛速度。尽管从幂法的角度去理解，Lanczos算法应该非常适合给出绝对值最大的几个本征值的近似解，实际上**Lanczos算法能够给出谱的两端的本征值的近似解**，即使它的绝对值可能比较小。这个性质使得它非常适合计算物理体系，毕竟很多时候我们只需要计算基态和几个低激发态。

下面是算法的细节，注意Lanczos算法适用于实对称矩阵（或厄米矩阵），这里假定$A$是实对称的，即有
$$
A = A^T, \quad (u, Av) = (Au, v)
$$

### 正交化

上述Krylov子空间中的向量并不是正交的，我们需要先得到这个空间的正交归一的基，然后再把$A$投影过来。基的选取是这样的

- 设初始向量为$v_1$，它是归一化的.
- 计算$w_1 = A v_1$，$w_1$和$v_1$并不正交，也不是归一的，对其做Gram-Schmidt正交化：
$$
\begin{aligned}
&\alpha_1 = (w_1, v_1) \\
&w_1 \leftarrow w_1 - \alpha_1 v_1
\end{aligned}
$$
- 再归一化得到新的基$v_2$
$$
\beta_2 = ||w_1||, \quad v_2 \leftarrow w_1/\beta_2
$$
- 继续这个过程$w_2 = Av_2$，Schmidt正交化
$$
\begin{aligned}
&\alpha_2 = (w_2, v_2) \\
&w_2 \leftarrow w_2 - \alpha_2 v_2 - (w_2, v_1)v_1
\end{aligned}
$$
第一个trick就发生在正交化的$v_1$这一项上，由于
$$
(w_2, v_1) = (Av_2, v_1) = (v_2, Av_1) = (v_2, \beta_2 v_2 + \alpha_1 v_1) = \beta_2
$$
其中第二个等号好用到了$A$的对称性，最后一个等式则是利用了$v_1, v_2$的正交归一性。所以第二步Schmidt正交化可以化简为
$$
\begin{aligned}
&\alpha_2 = (w_2, v_2) \\
&w_2 \leftarrow w_2 - \alpha_2 v_2 - \beta_2 v_1
\end{aligned}
$$
- 当然还要继续归一化得到新基$v_3$
$$
\beta_3 = ||w_2||, \quad v_3 \leftarrow w_2/\beta_3
$$
- 继续上述过程$w_3 = Av_3$，Schmidt正交化
$$
\begin{aligned}
&\alpha_3 = (w_3, v_3) \\
&w_3 \leftarrow w_3 - \alpha_3 v_3 - (w_3, v_2)v_2 - (w_3, v_1)v_1
\end{aligned}
$$
利用和前面一样的trick，有
$$
(w_3, v_2) = (Av_3, v_2) = (v_3, Av_2) = (v_3, \beta_3 v_3 + ...) = \beta_3
$$
省略号表示的是$v_1, v_2$的线性组合，因为他们和$v_3$正交，所以也没有计算的必要了。再算$v_1$的项
$$
(w_3, v_1) = (Av_3, v_1) = (v_3, Av_1) = (v_3, \beta_2v_2 + \alpha_1 v_2) = 0
$$
天然的等于零了，这是第二个trick。由此我们得到
$$
\begin{aligned}
&\alpha_3 = (w_3, v_3) \\
&w_3 \leftarrow w_3 - \alpha_3 v_3 - \beta_3v_2
\end{aligned}
$$

这个奇妙的数学结构正是Lanczos算法的精髓。我们不必继续下去了，可以发现之后的的Schmidt正交化过程中
$$
w_k \leftarrow w_k - \alpha_k v_k - \sum_{i = 1}^{k-1} (w_k, v_i)v_i
$$
由于
$$
(w_k, v_i) = (Av_k, v_i) = (v_k, Av_i)
$$
其中$Av_i$是$v_1, v_2, \dots, v_{i+1}$的线性组合，根据基的正交性，只有$(w_k, v_{k-1}) = \beta_k$不为零。这也就是说，Lanczos迭代过程中，仅仅需要$v_{k}$和$v_{k-1}$就可以完成正交化过程。

### 投影

接下来就是投影了，我们已经得到了$v_1, v_2, \dots, v_m$这组正交归一的基矢，矩阵$A$在这组基矢上的表示为
$$
(v_i, Av_j) = \begin{cases}
\beta_i, &i = j + 1 \\
\alpha_i, &i = j \\
\beta_j, &i = j - 1 \\
0, &\text{others}
\end{cases}
$$
对比正交化过程我们不难得到上述结果，换言之$A$在这组基上的投影是一个对称三对角矩阵
$$
T_{mm} = \begin{pmatrix}
\alpha_1 & \beta_2 & 0 & & & 0 \\
\beta_2 & \alpha_2 & \beta_3 & & & \\
0 & \beta_3 & \alpha_4 & \ddots & & \\
& & \ddots & \ddots & \beta_{m-1} & 0\\
& & & \beta_{m-1} & \alpha_{m-1} & \beta_m \\
0 & & & 0 & \beta_m & \alpha_m
\end{pmatrix}
$$
令$V_m = (v_1, v_2, \dots, v_m)$为基矢组成的矩阵，那么也就是
$$
T_{mm} = V^T_m A V_m
$$

求解$T_{mm}$的特征值问题即得到$A$的特征值的近似解，迭代过程就是增加$m$扩大Krylov子空间的大小。并非所有$T_{mm}$的特征值都是$A$的特征值的近似，但是谱两端的特征值随着迭代的过程是逐渐变得收敛的。

如果得到$T_{mm}$的几个特征值，和特征向量$t_1, t_2,\dots, t_k$，那么$A$的特征向量就是
$$
[x_1, x_2, \dots, x_k] = V_{m} [t_1, t_2, \dots, t_k]
$$

### 数值稳定性

Lanczos由于$A$的对称性带来的数学结构是在是非常优美。但是这也仅仅是数学上，要知道计算机浮点数计算是有误差的，这些误差的积累可能会使得$v_1, v_2, \dots, v_m$变得不再正交。如此一来可能会在解$T_{mm}$时得到简并的假态，他们对应的$T_{mm}$的特征向量$t_i, t_j$是不一样的，但是真实特征向量
$$
V_{m} t_i \approx V_m t_j
$$
是几乎相等的，因为此时$V_{m}$已经不是正交基矢了。

如果不加处理，这种现象几乎是必然发生的。这是因为Lanczos算法大致上可以看做一种投影算法，它对于谱两端的特征向量的投影是非常迅速的（这也是为什么Lanczos算法如此有效）。在正交化过程中，基态已经被投影出去一份了，如果正交化是严格的，那么当然不会产生基态的假态。但是随着误差的产生，剩余向量中又产生了随机出来的基态的成分，尽管成分可能很小，但是因为Lanczos的有效性，这个基态成分会迅速又被投影出来。

于是虽然数学上我们正交化仅需要前两个特征向量，但是我们可以每次迭代都实际上做完整的Schmidt正交化，这保证了数值上几乎的正交性。这增加的计算不是很大，但是需要你保存下所有的基矢$v_i$，如果你想要计算特征向量，那么显然你是要保存$V_{m}$的，所以这也不是不能接受。

而且你还是可以用三对角矩阵$T_{mm}$求解，因为其他那些数值误差带来的矩阵元是很小的。正如我们所说，假态不是单纯的随机数值误差造成的，而是Lanczos算法太有效造成的。完全正交化保证了数值上的正交性，就不会重新投影出假态了。

### 示例代码

```julia
using SparseArrays
using LinearAlgebra

"""
    Lanczos(A::AbstractMatrix, num::Int = 10)
其中`A`是待求解的矩阵，`num`是需要获得特征值的数目，默认为`10`.
"""
function Lanczos(A::AbstractMatrix, num::Int=10, maxiter=size(A, 1))
    @assert size(A, 1) == size(A, 2) "A should be square"
    @assert num < size(A, 1) / 2 "Lanczos cannot give too many eigen values"
    Asize = size(A, 1)
    T = float(eltype(A))
    eigen_values = zeros(T, num)
    eigen_vectors = zeros(T, Asize, num)
    α = T[]
    β = T[]
    V_list = Vector{Vector{T}}()
    # initial guess
    vk = rand(T, Asize)
    normalize!(vk)

    wk = A * vk
    ak = dot(wk, vk)
    push!(α, ak)
    push!(V_list, copy(vk))
    prev_eigen_value = typemax(T)
    k = 1
    while k < maxiter
        # orthogonalize
        if k == 1
            @. wk = wk - ak * vk
        else
            for i = k:-1:1
                ovlp = dot(wk, V_list[i])
                @. wk = wk - ovlp * V_list[i]
            end
        end
        k += 1
        bk = norm(wk)
        @. vk = wk / bk
        mul!(wk, A, vk)
        ak = dot(wk, vk)
        push!(α, ak)
        push!(β, bk)
        push!(V_list, copy(vk))

        # solve symtridiagonal
        Tkk = SymTridiagonal(α, β)
        vals, vecs = eigen(Tkk, 1:min(k, num))
        if k >= num
            if prev_eigen_value ≈ vals[end]
                eigen_values = vals
                eigen_vectors = hcat(V_list...) * vecs
                break
            else
                prev_eigen_value = vals[end]
            end
        end
    end
    if k >= maxiter
        @warn "not convereged after $k iterations"
    end
    return Eigen(eigen_values, eigen_vectors), k
end

function test_Lanczos(N::Int, nums::Int)
    A = sprandn(N, N, 1 / N)
    A = A + A'
    (vals, vecs), k = Lanczos(A, nums)
    println("convereged after $k iterations")
    println("first $nums eigen values = ", vals)
    println("first $nums eigen vectors residual norm = ")
    for i = 1:length(vals)
        println(norm(A * vecs[:, i] - vals[i] * vecs[:, i]))
    end
end

test_Lanczos(100, 10)
```

### 参考文献

- 刘川 《计算物理导论》
- Bai Z., Demmel J., Dongarra J., et al. (editors) - *Templates for the Solution of Algebraic Eigenvalue Problems: A Practical Guide*

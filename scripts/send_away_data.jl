### A Pluto.jl notebook ###
# v0.19.22

using Markdown
using InteractiveUtils

# ╔═╡ dd650878-ea12-11ed-26a3-8d1d59042949
using Serialization, Lux, Random, HDF5

# ╔═╡ b82cdc33-b5a9-4a1c-98e7-87cc87c1d673
begin
	struct Interpolate
		SET::Array{Int64, 1}
		locations::Array{Float32, 1}
		vecs::Array{Float32, 2}
	end
	
	function (itp::Interpolate)(t::Float32)
		i = searchsortedfirst(itp.locations, t)
		@inbounds val = itp.SET[i]
		@inbounds itp.vecs[val, :]
	end
	
	struct ArrayAndFuncs
		array::Array{Float32, 1}
		funcs::Array{Interpolate, 1}
	end
	
	function loadData(output_file::String, vecs)
		open(output_file, "r") do f
			input_funcs = deserialize(f)
			output = deserialize(f)
			return [Interpolate(x[1], x[2], vecs) for x in input_funcs], output
		end
	end

	function returnVecs(output_file::String)
		open(output_file, "r") do f
			input_funcs = deserialize(f)
			output = deserialize(f)
			vecs = nothing
			for x in input_funcs
				vecs = x[3]
			end
			return vecs
		end
	end
end

# ╔═╡ 528d96fc-59e1-4a9b-8efb-c59c10fbe4ac
test_vecs = returnVecs("../data/data_BDA/data_100_540.jls")

# ╔═╡ d42b0967-4d7c-48a3-b7bb-4fbb3ff217eb
function load_data_tensor(file_loc, vecs)
	input_data, output_data = loadData(file_loc, vecs)
	
	input_series = []
	for itp in input_data
		t = range(0.01f0, 0.50f0; step=0.01f0)
		input = [itp(x) for x in t]
		push!(input_series, hcat(input...))
	end
	
	input_vectors = permutedims(cat(input_series..., dims=3), (3,2,1))
	output_vectors = permutedims(output_data, (3,2,1))
	data_vectors = cat(input_vectors,output_vectors, dims=3)
	return data_vectors
end

# ╔═╡ c400ab7a-5997-4623-8aa1-f3ac1fa56b2b
load_data_tensor("../data/data_BDA/data_100_540.jls", test_vecs)

# ╔═╡ 98b8e6ed-b547-4ab0-8b87-fbbbd64b863a
load_data_tensor("../data/data_BDA/data_100_27.jls", test_vecs)

# ╔═╡ 3a50fba3-0113-41d0-841a-c692a10a5028
# ╠═╡ disabled = true
#=╠═╡
begin
	using HDF5

	train_data = load_data_tensor("../data/data_100_540_long.jls")
	test_data = load_data_tensor("../data/data_100_27_long.jls")
	
	h5open("../data/python_data_long.h5", "cw") do file
	    file["train_data"] = train_data
	    file["test_data"] = test_data
	end
end
  ╠═╡ =#

# ╔═╡ 3241100e-93a9-4884-b62a-b10a6abe8850
function interpolateVectors(vecs, beta::Float32)
	alpha = 1.0f0 - beta
	green = alpha*vecs[1:1, :] + beta*vecs[2:2, :]
	purple = alpha*vecs[2:2, :] + beta*vecs[3:3, :]
	red = alpha*vecs[3:3, :] + beta*vecs[1:1, :]
	return vcat(zeros(Float32, 1, 100), green, purple, red)
end

# ╔═╡ 382d8b6e-2174-4edc-829b-6eae6d7addb5
interpolateVectors(test_vecs[2:end, :], 0.0f0)

# ╔═╡ 6bdb06cf-ea57-4d45-b0a3-c156d0f2b7ed
function createInterpolateFiles(file_name, vecs, beta::Float32)
	new_vecs = interpolateVectors(vecs[2:end, :], beta)
	train_data = load_data_tensor("../data/data_BDA/data_100_540.jls", new_vecs)
	test_data = load_data_tensor("../data/data_BDA/data_100_27.jls", new_vecs)
	
	h5open(file_name, "cw") do file
	    file["train_data"] = train_data
	    file["test_data"] = test_data
	end
end

# ╔═╡ 3e0955db-8791-4129-a82a-524128040295
begin
	file_name = "../data/python_10_data.h5"
	beta = 1.0f0
	createInterpolateFiles(file_name, test_vecs, beta)
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
HDF5 = "f67ccb44-e63f-5c2f-98bd-6dc0ccc4ba2f"
Lux = "b2108857-7c20-44ae-9111-449ecde12c47"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
Serialization = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[compat]
HDF5 = "~0.16.14"
Lux = "~0.4.53"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.4"
manifest_format = "2.0"
project_hash = "4ff62bf1c97d1e22b068ffcc4c59921060c08d9c"

[[deps.AbstractFFTs]]
deps = ["ChainRulesCore", "LinearAlgebra"]
git-tree-sha1 = "16b6dbc4cf7caee4e1e75c49485ec67b667098a0"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.3.1"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "cc37d689f599e8df4f464b2fa3870ff7db7492ef"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.6.1"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Atomix]]
deps = ["UnsafeAtomics"]
git-tree-sha1 = "c06a868224ecba914baa6942988e2f2aade419be"
uuid = "a9b6321e-bd34-4604-b9c9-b65b8de01458"
version = "0.1.0"

[[deps.BFloat16s]]
deps = ["LinearAlgebra", "Printf", "Random", "Test"]
git-tree-sha1 = "dbf84058d0a8cbbadee18d25cf606934b22d7c66"
uuid = "ab4f0b2a-ad5b-11e8-123f-65d77653426b"
version = "0.4.2"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.CEnum]]
git-tree-sha1 = "eb4cb44a499229b3b8426dcfb5dd85333951ff90"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.2"

[[deps.CUDA]]
deps = ["AbstractFFTs", "Adapt", "BFloat16s", "CEnum", "CUDA_Driver_jll", "CUDA_Runtime_Discovery", "CUDA_Runtime_jll", "CompilerSupportLibraries_jll", "ExprTools", "GPUArrays", "GPUCompiler", "KernelAbstractions", "LLVM", "LazyArtifacts", "Libdl", "LinearAlgebra", "Logging", "Preferences", "Printf", "Random", "Random123", "RandomNumbers", "Reexport", "Requires", "SparseArrays", "SpecialFunctions", "UnsafeAtomicsLLVM"]
git-tree-sha1 = "280893f920654ebfaaaa1999fbd975689051f890"
uuid = "052768ef-5323-5732-b1bb-66c8b64840ba"
version = "4.2.0"

[[deps.CUDA_Driver_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "498f45593f6ddc0adff64a9310bb6710e851781b"
uuid = "4ee394cb-3365-5eb0-8335-949819d2adfc"
version = "0.5.0+1"

[[deps.CUDA_Runtime_Discovery]]
deps = ["Libdl"]
git-tree-sha1 = "bcc4a23cbbd99c8535a5318455dcf0f2546ec536"
uuid = "1af6417a-86b4-443c-805f-a4643ffb695f"
version = "0.2.2"

[[deps.CUDA_Runtime_jll]]
deps = ["Artifacts", "CUDA_Driver_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "5248d9c45712e51e27ba9b30eebec65658c6ce29"
uuid = "76a88914-d11a-5bdc-97e0-2f5a05c973a2"
version = "0.6.0+0"

[[deps.CUDNN_jll]]
deps = ["Artifacts", "CUDA_Runtime_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "2918fbffb50e3b7a0b9127617587afa76d4276e8"
uuid = "62b44479-cb7b-5706-934f-f13b2eb2e645"
version = "8.8.1+0"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "c6d890a52d2c4d55d326439580c3b8d0875a77d9"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.7"

[[deps.ChangesOfVariables]]
deps = ["LinearAlgebra", "Test"]
git-tree-sha1 = "f84967c4497e0e1955f9a582c232b02847c5f589"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.7"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "7a60c856b9fa189eb34f5f8a6f6b5529b7942957"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.6.1"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.1+0"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "89a9db8d28102b094992472d333674bd1a83ce2a"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.1"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.ExprTools]]
git-tree-sha1 = "c1d06d129da9f55715c6c212866f5b1bddc5fa00"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.9"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.Functors]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "478f8c3145bb91d82c2cf20433e8c1b30df454cc"
uuid = "d9f16b24-f501-4c13-a1f2-28368ffc5196"
version = "0.4.4"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GPUArrays]]
deps = ["Adapt", "GPUArraysCore", "LLVM", "LinearAlgebra", "Printf", "Random", "Reexport", "Serialization", "Statistics"]
git-tree-sha1 = "9ade6983c3dbbd492cf5729f865fe030d1541463"
uuid = "0c68f7d7-f131-5f86-a1c3-88cf8149b2d7"
version = "8.6.6"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "1cd7f0af1aa58abc02ea1d872953a97359cb87fa"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.1.4"

[[deps.GPUCompiler]]
deps = ["ExprTools", "InteractiveUtils", "LLVM", "Libdl", "Logging", "Scratch", "TimerOutputs", "UUIDs"]
git-tree-sha1 = "e9a9173cd77e16509cdf9c1663fda19b22a518b7"
uuid = "61eb1bfa-7361-4325-ad38-22787b887f55"
version = "0.19.3"

[[deps.HDF5]]
deps = ["Compat", "HDF5_jll", "Libdl", "Mmap", "Random", "Requires", "UUIDs"]
git-tree-sha1 = "3dab31542b3da9f25a6a1d11159d4af8fdce7d67"
uuid = "f67ccb44-e63f-5c2f-98bd-6dc0ccc4ba2f"
version = "0.16.14"

[[deps.HDF5_jll]]
deps = ["Artifacts", "JLLWrappers", "LibCURL_jll", "Libdl", "OpenSSL_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "4cc2bb72df6ff40b055295fdef6d92955f9dede8"
uuid = "0234f1f7-429e-5d53-9886-15a909be8d59"
version = "1.12.2+2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "6667aadd1cdee2c6cd068128b3d226ebc4fb0c67"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.9"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.KernelAbstractions]]
deps = ["Adapt", "Atomix", "InteractiveUtils", "LinearAlgebra", "MacroTools", "PrecompileTools", "SparseArrays", "StaticArrays", "UUIDs", "UnsafeAtomics", "UnsafeAtomicsLLVM"]
git-tree-sha1 = "47be64f040a7ece575c2b5f53ca6da7b548d69f4"
uuid = "63c18a36-062a-441e-b654-da1e3ab1ce7c"
version = "0.9.4"

[[deps.LLVM]]
deps = ["CEnum", "LLVMExtra_jll", "Libdl", "Printf", "Unicode"]
git-tree-sha1 = "a8960cae30b42b66dd41808beb76490519f6f9e2"
uuid = "929cbde3-209d-540e-8aea-75f648917ca0"
version = "5.0.0"

[[deps.LLVMExtra_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "09b7505cc0b1cee87e5d4a26eea61d2e1b0dcd35"
uuid = "dad2f222-ce93-54a1-a47d-0025e8a3acab"
version = "0.0.21+0"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "0a1b7c2863e44523180fdb3146534e265a91870b"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.23"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Lux]]
deps = ["Adapt", "ChainRulesCore", "Functors", "LinearAlgebra", "LuxCUDA", "LuxCore", "LuxLib", "Markdown", "NNlib", "Optimisers", "Random", "Requires", "Setfield", "SparseArrays", "Statistics", "TruncatedStacktraces"]
git-tree-sha1 = "a5c1691167a1ab915310f434d8de69bedcae6344"
uuid = "b2108857-7c20-44ae-9111-449ecde12c47"
version = "0.4.53"

[[deps.LuxCUDA]]
deps = ["CUDA", "NNlibCUDA", "Reexport", "cuDNN"]
git-tree-sha1 = "1c5470a996cdf15beb737f4739797e4e5f7a46f5"
uuid = "d0bbae9a-e099-4d5b-a835-1c6931763bda"
version = "0.1.2"

[[deps.LuxCore]]
deps = ["Functors", "Random", "Setfield"]
git-tree-sha1 = "094581e618e8ef57c7610eedd4ef56818197d32a"
uuid = "bb33d45b-7691-41d6-9220-0943567d0623"
version = "0.1.3"

[[deps.LuxLib]]
deps = ["ChainRulesCore", "KernelAbstractions", "Markdown", "NNlib", "Random", "Reexport", "Requires", "Statistics"]
git-tree-sha1 = "2be33a984180f2827220307fb2c269f1b19219e4"
uuid = "82251201-b29d-42c6-8e01-566dec8acb11"
version = "0.2.1"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "42324d08725e200c23d4dfb549e0d5d89dede2d2"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.10"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.NNlib]]
deps = ["Adapt", "Atomix", "ChainRulesCore", "GPUArraysCore", "KernelAbstractions", "LinearAlgebra", "Pkg", "Random", "Requires", "Statistics"]
git-tree-sha1 = "99e6dbb50d8a96702dc60954569e9fe7291cc55d"
uuid = "872c559c-99b0-510c-b3b7-b6c96a88d5cd"
version = "0.8.20"

[[deps.NNlibCUDA]]
deps = ["Adapt", "CUDA", "LinearAlgebra", "NNlib", "Random", "Statistics", "cuDNN"]
git-tree-sha1 = "f94a9684394ff0d325cc12b06da7032d8be01aaf"
uuid = "a00861dc-f156-4864-bf3c-e6376f28a68d"
version = "0.2.7"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9ff31d101d987eb9d66bd8b176ac7c277beccd09"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.20+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Optimisers]]
deps = ["ChainRulesCore", "Functors", "LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "6a01f65dd8583dee82eecc2a19b0ff21521aa749"
uuid = "3bd65402-5787-11e9-1adc-39752487f4e2"
version = "0.2.18"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "0c265aa64283740b9b885348ee52463084de0748"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.0.3"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Random123]]
deps = ["Random", "RandomNumbers"]
git-tree-sha1 = "552f30e847641591ba3f39fd1bed559b9deb0ef3"
uuid = "74087812-796a-5b5d-8853-05524746bad3"
version = "1.6.1"

[[deps.RandomNumbers]]
deps = ["Random", "Requires"]
git-tree-sha1 = "043da614cc7e95c703498a491e2c21f58a2b8111"
uuid = "e6cf234a-135c-5ec9-84dd-332b85af5143"
version = "1.5.3"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "30449ee12237627992a99d5e30ae63e4d78cd24a"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "e2cc6d8c88613c05e1defb55170bf5ff211fbeac"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.1"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "ef28127915f4229c971eb43f3fc075dd3fe91880"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.2.0"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "c262c8e978048c2b095be1672c9bee55b4619521"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.24"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6b7ba252635a5eff6a0b0664a41ee140a1c9e72a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TimerOutputs]]
deps = ["ExprTools", "Printf"]
git-tree-sha1 = "f548a9e9c490030e545f72074a41edfd0e5bcdd7"
uuid = "a759f4b9-e2f1-59dc-863e-4aeb61b1ea8f"
version = "0.5.23"

[[deps.TruncatedStacktraces]]
deps = ["InteractiveUtils", "MacroTools", "Preferences"]
git-tree-sha1 = "7bc1632a4eafbe9bd94cf1a784a9a4eb5e040a91"
uuid = "781d530d-4396-4725-bb49-402e4bee1e77"
version = "1.3.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnsafeAtomics]]
git-tree-sha1 = "6331ac3440856ea1988316b46045303bef658278"
uuid = "013be700-e6cd-48c3-b4a1-df204f14c38f"
version = "0.2.1"

[[deps.UnsafeAtomicsLLVM]]
deps = ["LLVM", "UnsafeAtomics"]
git-tree-sha1 = "ea37e6066bf194ab78f4e747f5245261f17a7175"
uuid = "d80eeb9a-aca5-4d75-85e5-170c8b632249"
version = "0.1.2"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.cuDNN]]
deps = ["CEnum", "CUDA", "CUDNN_jll"]
git-tree-sha1 = "ec954b59f6b0324543f2e3ed8118309ac60cb75b"
uuid = "02a925ec-e4fe-4b08-9a7e-0d78e3d38ccd"
version = "1.0.3"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╠═dd650878-ea12-11ed-26a3-8d1d59042949
# ╠═b82cdc33-b5a9-4a1c-98e7-87cc87c1d673
# ╠═528d96fc-59e1-4a9b-8efb-c59c10fbe4ac
# ╠═d42b0967-4d7c-48a3-b7bb-4fbb3ff217eb
# ╠═c400ab7a-5997-4623-8aa1-f3ac1fa56b2b
# ╠═98b8e6ed-b547-4ab0-8b87-fbbbd64b863a
# ╠═3a50fba3-0113-41d0-841a-c692a10a5028
# ╠═3241100e-93a9-4884-b62a-b10a6abe8850
# ╠═382d8b6e-2174-4edc-829b-6eae6d7addb5
# ╠═6bdb06cf-ea57-4d45-b0a3-c156d0f2b7ed
# ╠═3e0955db-8791-4129-a82a-524128040295
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002

using Base.Test, HDF5, DSGE
include("../util.jl")

# Set up model for testing
m = Model990()
toggle_test_mode(m)

# Read in the covariance matrix for Metropolis-Hastings and reference parameter draws
reference_fn  = joinpath(dirname(@__FILE__), "metropolis_hastings.h5")
h5_ref        = h5open(reference_fn, "r")
propdist_cov  = read(h5_ref, "propdist_cov")
ref_draws     = read(h5_ref, "ref_draws")
ref_cov       = read(h5_ref, "ref_cov")
close(h5_ref)

# Set up and run metropolis-hastings
DSGE.estimate(m, verbose=:none, proposal_covariance = propdist_cov)

# Read in the parameter draws from estimate()
h5_fn        = joinpath(outpath(m), "sim_save.h5")
h5           = h5open(h5_fn, "r")
test_draws   = read(h5, "parasim")
close(h5)

h5_cov_fn    = joinpath(outpath(m),"parameter_covariance.h5")
h5_cov       = h5open(h5_cov_fn, "r")
test_cov     = read(h5_cov, "param_covariance")
close(h5_cov)


# Test that the fixed parameters are all fixed
for fixed_param in [:δ, :λ_w, :ϵ_w, :ϵ_p, :g_star]
    @test test_draws[:,m.keys[fixed_param]] == fill(@compat(Float32(m[fixed_param].value)), 100)
end

# Test that the parameter draws are equal
@test test_matrix_eq(ref_draws, test_draws, ϵ=1e-6)

# Test that the covariance matrices are equal
@test test_matrix_eq(ref_cov, test_cov, ϵ=1e-6)

# Make sure that compute_moments runs appropriately
compute_moments(m, verbose=false)

# Remove the files generated by the test
rm(h5_fn)
rm(h5_cov_fn)

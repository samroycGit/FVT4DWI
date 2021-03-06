% 3D scalar example
% Author: Aina Frau-Pascual

%%
% Input image
im = zeros(3,3,3);
im(:,:,1) = 1;
im(:,1,:) = 1;
im(3,3,3) = 1;

%%
% Construct mesh structure
Lx = size(im, 1); % domain length
Nx = size(im, 1); % number of cells
Ly = size(im, 2); % domain length
Ny = size(im, 2); % number of cells
Lz = size(im, 3); % domain length
Nz = size(im, 3); % number of cells
meshstruct = createMesh3D(Nx, Ny, Nz, Lx, Ly, Lz); % construct mesh
x = meshstruct.cellcenters.x; % extract the cell center positions

% Define the boundary condition:
BC = createBC(meshstruct); % all Neumann boundary condition structure
[Mbc, RHSbc] = boundaryCondition(BC); % boundary condition discretization

%%
% Define the transfer coefficients:
D = createCellVariable(meshstruct, im);
Dave = harmonicMean(D);          % convert a cell variable to face variable
Mdiff = diffusionTerm(Dave);     % diffusion term
M = Mdiff + Mbc;                 % matrix of coefficient for central scheme

%%
% Define mask
G = reshape(1:(Nx+2)*(Ny+2)*(Nz+2), Nx+2, Ny+2, Nz+2);
mnx = Nx*Ny*Nz;	mny = Nx*Ny*Nz; mnz = Nx*Ny*Nz;
rowx_index = reshape(G(2:Nx+1,2:Ny+1,2:Nz+1),mnx,1); % main diagonal x
rowy_index = reshape(G(2:Nx+1,2:Ny+1,2:Nz+1),mny,1); % main diagonal y
rowz_index = reshape(G(2:Nx+1,2:Ny+1,2:Nz+1),mnz,1); % main diagonal z

%%
% Compute conductance
conductance = zeros(size(RHSbc, 1), size(RHSbc, 1));
for p1=rowx_index'
    for p2=rowy_index'
        if p2>=p1
            RHSbc0 = RHSbc;
            RHSbc0(p1) = 1; % define current i
            RHSbc0(p2) = -1; % define current j
            c = solvePDE(meshstruct, M, RHSbc0); % solve for the central scheme
            conductance(p1, p2) = abs(1 / (c.value(p1) - c.value(p2)));
            conductance(p2, p1) = conductance(p1, p2);
        end
    end
end
conductance(isnan(conductance)) = 0;


%%
% Plot results
f = figure; f.Name = 'Original image 3x3x3'; 
set(gcf,'position', [300, 300, 1000, 180]);
subplot(1,3,1), imagesc(im(:,:,1,1), [0,1]); colorbar; xlabel('x'); ylabel('y');
subplot(1,3,2), imagesc(im(:,:,2,1), [0,1]); colorbar; xlabel('x'); ylabel('y');
subplot(1,3,3), imagesc(im(:,:,3,1), [0,1]); colorbar; xlabel('x'); ylabel('y');

figure,
image(conductance(rowx_index,rowy_index), 'CDataMapping', 'scaled'); 
colorbar; title('Conductance matrix derived from original image');
xlabel('voxel i'); ylabel('voxel s');

function [J, G, H] = elliptic_nonlinear_2D_2_fun(u, pars)

%--------------------------------------------------------------------------
% 2D bratu equation:
%
%   \Omega = [0,1]*[0,1]
%   - div grad u + lambda*u + u*|u| = f
%           u = 0 on boundary
%
%  ===> min J(u) = \int 0.5 * |grad u|^2  + 1/2 lambda u^2 + 1/3 |u|^3  - f*u dx
%
%   \Omega = [0,1]*[0,1]
%   - div grad u + lambda*u + u*|u|^3 = f
%           u = 0 on boundary
%
%  ===> min J(u) = \int 0.5 * |grad u|^2  + 1/2 lambda u^2 + 1/5 |u|^5  - f*u dx
%   
%   gradient, hessian: only respect to interior points
%

%--------------------------------------------------------------------------

[nx, ny] = size(u);
dx = 1/(nx-1);  dy = 1/(ny-1);

area = dx*dy;
% area = dx*dy;


%-------------------------------------------------
% set right hand side b
%   f = x.^6 
x = 0:dx:1;     y = 0:dy:1;
[X Y] = meshgrid(x,y);
f = X.^6;

% f = sin(X)  + X.^6;

lambda = -5;

delta_u_x_fwd = ( u(2:end,1:end-1) - u(1:end-1,1:end-1) )/dx;
delta_u_y_fwd = ( u(1:end-1,2:end) - u(1:end-1,1:end-1) )/dy;

delta_u_x_bwd = ( u(2:end,2:end) - u(1:end-1,2:end) )/dx;
delta_u_y_bwd = ( u(2:end,2:end) - u(2:end,1:end-1) )/dy;

% f_u = (1/2) * lambda* u.^2 + (1/3) * abs(u).^3 - f.*u ;
% f_u = (1/2) * lambda* u.^2 + (1/5) * abs(u).^5 - f.*u ;
f_u = (1/2) * u.^2 + (1/5) *lambda*  abs(u).^5 - f.*u ;


% forward difference
J =  area* sum( sum( 0.5 *(delta_u_x_fwd.^2 + delta_u_y_fwd.^2)...
         + f_u(1:end-1,1:end-1) ) );
 
% backward difference     
J = J +  area * sum( sum( 0.5 * (delta_u_x_bwd.^2 + delta_u_y_bwd.^2)...
         + f_u(2:end, 2:end) ) ) ;

% compute gradient
if nargout > 1

    % forward difference
   
    Gx = delta_u_x_fwd;
    Gy = delta_u_y_fwd;
%     Gz =  lambda * u(2:end-1,2:end-1) + u(2:end-1,2:end-1).* abs(u(2:end-1,2:end-1)) - f(2:end-1,2:end-1);
%     Gz =  lambda * u(2:end-1,2:end-1) + u(2:end-1,2:end-1).* (abs(u(2:end-1,2:end-1))).^3 - f(2:end-1,2:end-1);
    Gz =   u(2:end-1,2:end-1) + lambda * u(2:end-1,2:end-1).* (abs(u(2:end-1,2:end-1))).^3 - f(2:end-1,2:end-1);


    G = (1/dx) *( Gx(1:end-1,2:end) -  Gx(2:end,2:end) ) ...
        + (1/dy) * ( Gy(2:end,1:end-1) -  Gy(2:end,2:end) ) ...
        + Gz ;

    % backward difference
    Gx = delta_u_x_bwd;
    Gy = delta_u_y_bwd;
%     Gz =  - 0.5*lambda_expu(2:end-1,2:end-1);

    G = G + (1/dx) *( Gx(1:end-1,1:end-1) -  Gx(2:end,1:end-1) ) ...
        + (1/dy) * ( Gy(1:end-1,1:end-1) -  Gy(1:end-1,2:end) ) ...
        + Gz;  
    
    G = area * [zeros(1,nx); zeros(nx-2,1) G zeros(nx-2,1); zeros(1,nx)];

end

if nargout > 2
    % Set dimension of hessian
    nx2 = (nx - 2);   ny2 = (ny - 2);

    dx2 = 1/(dx)^2;     dy2 = 1/(dy)^2;     dxy = 1/dx/dy;

    % forward difference---------------------------------------------------
    Hxx = dx2 * ones(nx-1,nx-1);
    Hxy = dxy * zeros(nx-1,nx-1);
    Hyy = dy2 * ones(nx-1,nx-1);
%     Hzz =  abs(u(2:end-1,2:end-1)) + u(2:end-1,2:end-1).*sign(u(2:end-1,2:end-1))  + lambda;
%     Hzz =  (abs(u(2:end-1,2:end-1))).^3 + 3*(u(2:end-1,2:end-1).^2).* (abs(u(2:end-1,2:end-1)))  + lambda;
    Hzz =  lambda * ( (abs(u(2:end-1,2:end-1))).^3 + 3*(u(2:end-1,2:end-1).^2).* (abs(u(2:end-1,2:end-1))) ) + 1 ;

 
    % diagonal element ((i,j), (i,j))
    H1 = ( Hxx(1:end-1,2:end) +  Hxx(2:end,2:end) ) + ...
         ( Hyy(2:end,1:end-1) +  Hyy(2:end,2:end) ) + ...
            2 *  Hxy(2:end,2:end) + Hzz + ...
         ( Hxx(1:end-1,1:end-1) +  Hxx(2:end,1:end-1) ) + ...
         ( Hyy(1:end-1,1:end-1) +  Hyy(1:end-1,2:end) ) + ...
         2 *  Hxy(1:end-1,1:end-1) + Hzz;
     
    H1 = H1(:);

    %  element ((i,j), (i+1,j))
    H2 =  -Hxx(2:end,2:end) -  Hxy(2:end,2:end) ...
          -Hxx(2:end,1:end-1) -  Hxy(2:end,1:end-1);
    H2(end,:) = 0;
    H2 = H2(:);

    %  element ((i+1,j), (i,j+1))
    H3 =  Hxy(2:end,2:end) +  Hxy(2:end,2:end);
    H3(end,:) = 0;
    H3 = H3(:);

    %  element ((i,j), (i,j+1))
    H4 =  - Hxy(2:end,2:end) - Hyy(2:end,2:end) ...
          - Hxy(1:end-1,2:end) - Hyy(1:end-1,2:end);
    H4 = H4(:);

    H = area * spdiags([H4 [0;H3(1:end-1)] H2 H1 [0;H2(1:end-1)]  [zeros(nx-2,1);H3(1:end-nx+2)] [zeros(nx-2,1);H4(1:end-nx+2)]], ...
        [-(nx-2) -(nx-3) -1 0 1 (nx-3) (nx-2)] , (nx-2)^2 , (ny-2)^2);

    
%     % diagonal element ((i,j), (i,j))
%     H1 = ( Hxx(1:end-1,2:end) +  Hxx(2:end,2:end) ) + ...
%          ( Hyy(2:end,1:end-1) +  Hyy(2:end,2:end) ) + ...
%          2 *  Hxy(2:end,2:end) + Hzz;
%     H1 = H1(:);
% 
%     %  element ((i,j), (i+1,j))
%     H2 =  -Hxx(2:end,2:end) -  Hxy(2:end,2:end);
%     H2(end,:) = 0;
%     H2 = H2(:);
% 
%     %  element ((i+1,j), (i,j+1))
%     H3 =  Hxy(2:end,2:end);
%     H3(end,:) = 0;
%     H3 = H3(:);
% 
%     %  element ((i,j), (i,j+1))
%     H4 =  - Hxy(2:end,2:end) - Hyy(2:end,2:end);
%     H4 = H4(:);
% 
%     H = spdiags([H4 [0;H3(1:end-1)] H2 H1 [0;H2(1:end-1)]  [zeros(nx-2,1);H3(1:end-nx+2)] [zeros(nx-2,1);H4(1:end-nx+2)]], ...
%         [-(nx-2) -(nx-3) -1 0 1 (nx-3) (nx-2)] , (nx-2)^2 , (ny-2)^2);
% 
% 
% 
%     % backward difference---------------------------------------------------
%     Hxx = dx2 * ones(nx-1,nx-1);
%     Hxy = dxy * zeros(nx-1,nx-1);
%     Hyy = dy2 * ones(nx-1,nx-1);
% 
%     % diagonal element ((i,j), (i,j))
%     H1 = ( Hxx(1:end-1,1:end-1) +  Hxx(2:end,1:end-1) ) + ...
%          ( Hyy(1:end-1,1:end-1) +  Hyy(1:end-1,2:end) ) + ...
%          2 *  Hxy(1:end-1,1:end-1) + Hzz;
%     H1 = H1(:);
% 
%     %  element ((i,j), (i-1,j))
%     H2 =  -Hxx(2:end,1:end-1) -  Hxy(2:end,1:end-1);
%     H2(end,:) = 0;
%     H2 = H2(:);
% 
%     %  element ((i-1,j), (i,j-1))
%     H3 =  Hxy(2:end,2:end);
%     H3(end,:) = 0;
%     H3 = H3(:);
% 
%     %  element ((i,j), (i,j-1))
%     H4 =  - Hxy(1:end-1,2:end) - Hyy(1:end-1,2:end);
%     H4 = H4(:);
% 
% 
%     H = H + spdiags([H4 [0;H3(1:end-1)] H2 H1 [0;H2(1:end-1)]  [zeros(nx-2,1);H3(1:end-nx+2)] [zeros(nx-2,1);H4(1:end-nx+2)]], ...
%         [-(nx-2) -(nx-3) -1 0 1 (nx-3) (nx-2)] , (nx-2)^2 , (ny-2)^2);
% 
%     H = area * H;
%


end


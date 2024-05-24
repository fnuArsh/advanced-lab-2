function [V,T,M,h]=PhotoGateOscilloscope(port,N,dt,pauseit,plotit,M,baud)
% PhotoGateOscilloscope <Measure Voltage vs Time>
% Usage:: [V,T,N]=SimpleOscilloscope(port,N[1],dt[0],pauseit[false],plotit[true],M[768],baud[115200])
%

% revision history:
% 01/28/21 Mark D. Shattuck <mds> simpleOscilloscope.m
% 04/30/21 mds add wait for bytes available

%% Parse Input
if(~exist('N','var') || isempty(N))
  N=1;
end

if(~exist('dt','var') || isempty(dt))
  dt=0;
end

if(~exist('M','var') || isempty(M))
  M=768;
end

if(~exist('plotit','var') || isempty(plotit))
  plotit=true;
end

if(~exist('pauseit','var') || isempty(pauseit))
  pauseit=false;
end

if(~exist('baud','var') || isempty(baud))
  baud=115200;
end

%% Setup serial port

s=serial(port,'baud',baud);  % Create serial object
fopen(s);                    % Open serial port
pause(2);                    % pause to allow time for communication

%% Main 

fprintf(s,'?');        % Send character '?' to see if ok
str=fgetl(s);          % get response: must be 'K' 
if(char(str(1))=='K')
  fprintf('Communication established.\n');
  
  V=zeros(N,M);   % storage for (V)oltage counts
  T=zeros(N,1);   % storage for total acquision (T)ime
  if(plotit)
    t=(0:M-1)/M;    % time variable for ploting
  end
  % loop over N runs
  for n=1:N;
    fprintf('Run: %d\n',n);
    if(pauseit); pause; end % pause if pauseit is true
    
    % create go command
    com=sprintf('g%d',dt);  % e.g., g1000 means go at sample rate 1000us
    fprintf(s,com);         % Send command
    
    % wait for data
    dd=M*dt/1e6;                  % time to delay
    if(dd>2)                      % feedback only for long pauses
      idd=floor(dd);
      Nc=length(sprintf('%d',idd));
      fmt=sprintf('[%%0%dd/%%0%dd]',Nc,Nc);
      fprintf('Acquiring data ');
      tic;
      fprintf(1,fmt,fix(toc),idd);
      while(s.BytesAvailable==0)
        pause(.05);
        cdd=fix(toc);
        backspace(1,fmt,cdd,idd);
        fprintf(1,fmt,cdd,idd);     
      end
      backspace(1,fmt,idd,idd);
      fprintf(1,fmt,idd,idd);
      fprintf('...Done.\n')
    end
    
    % loop over samples
    for m=1:M
      V(n,m)=str2double(fgetl(s));    % store sample
    end
    T(n)=str2double(fgetl(s));        % store total sample time
    
    % plot if plotit true
    if(plotit)
      h=plot(t*T(n),V(n,:));  % convert time to us
      axis([0 inf 0 1024]);   % set to full range
      xlabel('time (us)');    % label axes
      ylabel('Counts');
      drawnow;                % draw during loop
    end
  end
else
  V=-1;
  T=-1;
  fprintf('Communication could NOT be established.\n');
end  
%% Always close use: fclose(instrfind);delete(instrfind) to close orphans
fclose(s);
delete(s);
clear s;

function backspace(fid,fmt,varargin)
% backspace Move cursor back according to size of fmt.
% Usage:: backspace(fid,fmt,varargin)
%
% Will move cursor back according to size of fmt.  Typically to give users
% feedback in the form of a count: 
%
%    Nc=length(sprintf('%d',Nbuf));
%    fmt=sprintf('[%%0%dd/%%0%dd]',Nc,Nc);
%    fprintf(1,fmt,0,Nbuf);
%    for n=1:Nbuf
%      < code; > 
%      backspace(1,fmt,n,Nbuf);
%      fprintf(1,fmt,n,Nbuf);
%    end
%  

% revision history:
% 02/12/01 Mark D. Shattuck <mds> backspace.m  

fprintf(fid,char(8*ones(length(sprintf(fmt,varargin{:})),1)));

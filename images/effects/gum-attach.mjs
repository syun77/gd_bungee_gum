import { fit, Rng, TAU, clamp } from '../../pixelfx/src/core/index.js';

export const meta = {
  name: 'Gum adhesion',
  desc: 'A glossy pink gum patch squashes, stretches elastic fingers and recoils into its adhesion point.',
  tags: ['gum', 'adhesion', 'elastic', 'impact'],
  size: [64, 64], origin: [32, 32], duration: 0.3, fps: 30, loop: false, bg: 'dark',
  options: { palette: ['#783d60', '#ae4d7c', '#e864a0', '#ff91bf', '#ffc4dc', '#fff3df'], seed: 7, radial: false },
};

const mix = (a,b,k) => a+(b-a)*k;
function capsule(x,y,ax,ay,bx,by,r0,r1) {
  const dx=bx-ax,dy=by-ay;
  const u=clamp(((x-ax)*dx+(y-ay)*dy)/(dx*dx+dy*dy || 1));
  return Math.hypot(x-ax-dx*u,y-ay-dy*u)-mix(r0,r1,u);
}

export function draw(p,t,o) {
  if (t < 0 || t >= meta.duration) return;
  const C=fit(o.palette,6), rng=new Rng(o.seed);
  const spread=Math.sin(Math.PI*clamp(t/0.26))**0.65;
  const fade=1-clamp((t-0.19)/0.11);
  const swell=t<0.04 ? mix(0.5,1,t/0.04) : 1;
  const core=(2.5+3*spread)*fade*swell;
  const fingers=Array.from({length:o.radial?7:5},(_,i)=> {
    const a=o.radial ? i*TAU/7+rng.range(-0.12,0.12) : Math.PI/2+i*Math.PI/4+rng.range(-0.1,0.1);
    const length=(8+rng.range(0,5))*spread*fade;
    return {a,length,r:mix(3.8,0.8,clamp(t/0.20))*fade};
  });
  function field(x,y) {
    const cx=o.radial?0:-1;
    let d=Math.hypot((x-cx)/(o.radial?1:0.65),y)-core;
    for(const f of fingers) {
      const ax=Math.cos(f.a)*core*0.45,ay=Math.sin(f.a)*core*0.45;
      const bx=Math.cos(f.a)*(core+f.length),by=Math.sin(f.a)*(core+f.length);
      const bend=Math.sin(f.a*3+0.7)*spread*2;
      const mx=(ax+bx)*0.5-Math.sin(f.a)*bend;
      const my=(ay+by)*0.5+Math.cos(f.a)*bend;
      const b=Math.min(capsule(x,y,ax,ay,mx,my,core*0.65,f.r*0.8),
        capsule(x,y,mx,my,bx,by,f.r*0.8,f.r));
      const h=Math.max(2.2-Math.abs(d-b),0)/2.2;
      d=Math.min(d,b)-h*h*0.55;
    }
    return d;
  }
  p.shade(-25,-25,25,25,(x,y)=> {
    const d=field(x,y);
    if(d>0) return;
    if(d> -0.9) return C[0];
    const top=field(x-0.8,y-1.2)>-0.7;
    if(top) return C[4];
    if(field(x+0.7,y+1.1)>-0.8) return C[1];
    return y < -core*0.15 ? C[3] : C[2];
  });
  if(t<0.067) {p.ellipse(-1,-1,2.4,1.5,C[5]);p.glow(-1,0,12,C[3],0.15*(1-t/0.067));}
  if(t>0.08 && t<0.23) {
    const q=(t-0.08)/0.15, r=core+10*Math.sin(Math.PI*q);
    for(const a of (o.radial?[-0.6,2.2,4.1]:[2.4,3.8])) {
      const x=Math.cos(a)*r,y=Math.sin(a)*r;
      p.ellipse(x,y,1.3*(1-q),1.7*(1-q),C[2]);
      p.px(x-0.5,y-0.6,C[4]);
    }
  }
}

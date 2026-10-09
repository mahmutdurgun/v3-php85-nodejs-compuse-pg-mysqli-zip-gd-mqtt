#!/usr/bin/env python3
"""Linux Docker sunucusunda: sudo python3 new-container.py proje1"""
import fcntl,json,os,re,socket,subprocess,sys
from pathlib import Path
HERE=Path(__file__).resolve().parent
IMAGE='mahmut-php-web:8.5-v3'

def ensure_image():
    result=subprocess.run(['docker','image','inspect',IMAGE],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    if result.returncode != 0:
        print('İmaj ilk kez hazırlanıyor; sonraki projelerde yeniden derlenmeyecek.',flush=True)
        run(['docker','build','--pull','-t',IMAGE,str(HERE)])
    else:
        print('Hazır yerel imaj kullanılıyor.',flush=True)

def run(args,**kw):
    return subprocess.run(args,check=True,**kw)

def free(port):
    try:
        with socket.socket() as s:
            s.bind(('0.0.0.0',port))
        return True
    except OSError:
        return False

def choose(used,available=free):
    for offset in range(100):
        http,ssh=300+offset,400+offset
        if http not in used and ssh not in used and available(http) and available(ssh):
            return http,ssh
    raise RuntimeError('300–399 HTTP / 400–499 SSH aralığında boş port çifti yok.')

def main():
    if len(sys.argv)!=2 or not re.fullmatch(r'[a-z0-9][a-z0-9_-]*',sys.argv[1]):
        raise SystemExit('Kullanım: sudo python3 new-container.py proje1 (küçük harf)')
    name=sys.argv[1]
    root=Path(os.environ.get('WEB_ROOT','/home/umbrel/web')).resolve()
    root.mkdir(parents=True,exist_ok=True)
    with (root/'.container-ports.lock').open('a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        ids=run(['docker','ps','-aq'],capture_output=True,text=True).stdout.split()
        containers=json.loads(run(['docker','inspect',*ids],capture_output=True,text=True).stdout) if ids else []
        if any(c.get('Config',{}).get('Labels',{}).get('com.docker.compose.project')==name for c in containers):
            raise SystemExit('Bu proje zaten mevcut. Güncellemek için README talimatını kullanın.')
        used=set()
        for c in containers:
            for binds in (c.get('HostConfig',{}).get('PortBindings') or {}).values():
                for b in binds or []:
                    if b.get('HostPort'): used.add(int(b['HostPort']))
        project=root/name
        if project.exists():
            raise SystemExit('Proje klasörü zaten mevcut; veri ve port ayarlarını korumak için duruldu.')
        http,ssh=choose(used)
        ensure_image()
        project.mkdir()
        (project/'www').mkdir()
        env=project/'compose.env'
        env.write_text(f'COMPOSE_PROJECT_NAME={name}\nWEB_ROOT={root}\nHOST_HTTP_PORT={http}\nHOST_SSH_PORT={ssh}\n')
        run(['docker','compose','--env-file',str(env),'-p',name,'-f',str(HERE/'docker-compose.yml'),'up','-d','--no-build','--pull','never'])
        print(f'HTTP: {http} → 80 | SSH/SFTP: {ssh} → 22 | HTML: {project / "www"}')
if __name__=='__main__': main()

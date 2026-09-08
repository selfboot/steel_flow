"""Read-only release verification using the configured App Store Connect API key."""
import base64, json, os, sys, time, urllib.request
from pathlib import Path
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature

def encode(value):
    return base64.urlsafe_b64encode(value).rstrip(b'=').decode()
header = encode(json.dumps({'alg':'ES256','kid':os.environ['ASC_KEY_ID'],'typ':'JWT'}, separators=(',',':')).encode())
now = int(time.time())
payload = encode(json.dumps({'iss':os.environ['ASC_ISSUER_ID'],'iat':now,'exp':now+600,'aud':'appstoreconnect-v1'}, separators=(',',':')).encode())
message = (header+'.'+payload).encode()
key = serialization.load_pem_private_key(Path(os.environ['ASC_KEY_PATH']).read_bytes(), password=None)
r,s = decode_dss_signature(key.sign(message,ec.ECDSA(hashes.SHA256())))
token = message.decode()+'.'+encode(r.to_bytes(32,'big')+s.to_bytes(32,'big'))
path = sys.argv[1]
assert path.startswith('/v1/')
request = urllib.request.Request('https://api.appstoreconnect.apple.com'+path,headers={'Authorization':'Bearer '+token})
with urllib.request.urlopen(request,timeout=45) as response:
    result=json.load(response)
if len(sys.argv)>2:
    Path(sys.argv[2]).write_text(json.dumps(result,ensure_ascii=False,indent=2))
for entry in result.get('data',[]) if isinstance(result.get('data'),list) else [result.get('data',{})]:
    print(json.dumps({'id':entry.get('id'),'type':entry.get('type'),'attributes':entry.get('attributes')},ensure_ascii=False))

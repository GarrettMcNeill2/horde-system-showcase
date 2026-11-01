"""Regenerate website-ready SVG diagrams. Python 3, standard library only."""
from pathlib import Path
from html import escape
OUT=Path(__file__).resolve().parents[1]/'media'

def diagram(name,title,subtitle,boxes,arrows,footnotes):
    items=['<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="1000" viewBox="0 0 1600 1000" role="img" aria-labelledby="title desc">',f'<title id="title">{escape(title)}</title><desc id="desc">{escape(subtitle)}</desc>', '<defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="4" orient="auto"><path d="M0 0L8 4L0 8" fill="none" stroke="#68d8cb" stroke-width="1.5"/></marker></defs>', '<rect width="1600" height="1000" fill="#0c1522"/>','<path d="M60 136H1540" stroke="#294055"/>',f'<text x="60" y="72" fill="#f2f6fa" font-family="Arial,sans-serif" font-size="36" font-weight="700">{escape(title)}</text>',f'<text x="60" y="112" fill="#a9bed1" font-family="Arial,sans-serif" font-size="21">{escape(subtitle)}</text>']
    for x,y,w,h,label,lines in boxes:
        items.extend([f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="#142537" stroke="#36536a"/>',f'<rect x="{x}" y="{y+18}" width="4" height="32" fill="#68d8cb"/>',f'<text x="{x+24}" y="{y+40}" fill="#68d8cb" font-family="Arial,sans-serif" font-size="23" font-weight="700">{escape(label)}</text>'])
        for n,line in enumerate(lines):
            items.append(f'<text x="{x+24}" y="{y+80+n*30}" fill="#e1eaf3" font-family="Arial,sans-serif" font-size="20">{escape(line)}</text>')
    for path in arrows:
        items.append(f'<path d="{path}" fill="none" stroke="#68d8cb" stroke-width="2" marker-end="url(#arrow)"/>')
    for n,line in enumerate(footnotes):
        items.append(f'<text x="60" y="{912+n*29}" fill="#a9bed1" font-family="Arial,sans-serif" font-size="19">{escape(line)}</text>')
    items.append('</svg>')
    (OUT/f'{name}.svg').write_text('\n'.join(items))

diagram('workflow','Horde simulation workflow','Fixed physics updates own state. Render updates interpolate transforms and advance the VAT clock.',[
(60,180,440,220,'01 / Horde brain',['detect_player() → idle / roam / chase','Shared intent and brain navigation','Abduction schedules staggered deaths']),
(580,180,440,220,'02 / Individual agents',['Gravity → effects → state transition','State action → face_and_render()','Packed arrays; no node per zombie']),
(1100,180,440,220,'03 / Budgeted navigation',['Queue stable zombie IDs','process_path_requests(): budget 16','Retries spread requests over ticks']),
(1100,500,440,220,'04 / Spatial queries + combat',['Rebuild 5 m cells after movement','Radius / AABB broad phase','Shape test → damage / knockback']),
(580,500,440,220,'05 / Animation metadata',['State → clip and playback rate','Outgoing clip keeps advancing','die(): swap last agent into removed slot']),
(60,500,440,220,'06 / Render update',['Interpolate previous/current transforms','Flush changed blend texture metadata','MultiMesh → VAT vertex shader']),
],['M500 290H580','M1020 290H1100','M1320 400V500','M1100 610H1020','M580 610H500'],[
'Source: scripts/enemies/horde.gd and addons/openvat_animated/src/open_vat_blend_controller.gd.',
'Array iteration stays O(N). Spatial hashing narrows candidates; dense cells and path queues can still be costly.'
])

diagram('gpu-pipeline','CPU → GPU rendering pipeline','Resource updates and shader stages used to render the horde.',[
(60,180,440,250,'CPU / Simulation',['_physics_process(): positions + states','_process(): interpolated transforms','request_clip(): two advancing clips','flush(): upload dirty metadata']),
(580,180,440,250,'Engine / Resource updates',['MultiMesh instance transforms','INSTANCE_CUSTOM: phase / frames / alpha','COLOR: loop flag / timestamp / fps','RGBAF texture: 3 rows per instance']),
(1100,180,440,250,'GPU / Vertex stage',['Read VAT positions + packed normals','Interpolate adjacent baked frames','When blending: sample outgoing clip','Crossfade → deformed vertex + normal']),
(1100,530,440,230,'GPU / Fragment stage',['Albedo and material texture samples','Lighting, depth and transparency','Rasterize instanced zombie surfaces']),
(60,530,960,230,'Cost and draw-call interpretation',['Instancing batches repeated geometry for each surface and rendering pass.','Pass count depends on surfaces, shadows, transparency, lighting and renderer.','One active crossfade adds outgoing VAT samples and metadata reads per vertex.','AI, navigation, ground rays and instance transform updates remain CPU work.']),
],['M500 300H580','M1020 300H1100','M1320 430V530'],[
'Source: openvat_instanced.gdshader, OpenVATBlendController.flush(), Horde._process().',
'Use a graphics debugger on the target renderer for actual API calls and GPU timings; HUD draw calls cover the whole scene.'
])

diagram('spatial-and-lifecycle','Spatial queries and stable agent identity','Broad-phase lookup reduces candidate work; stable IDs keep delayed work valid when arrays compact.',[
(60,180,700,270,'Spatial query path',['Position → floor(X / 5), floor(Z / 5) → cell key','rebuild_spatial_hash(): cell → agent array indices','query_radius() / query_aabb(): visit relevant cells','Narrow phase checks distance or hit geometry','Avoidance caps accepted neighbors at 8; candidates may exceed 8']),
(840,180,700,270,'Deferred path request',['Queue stores a stable zombie ID','process_path_requests() resolves ID at consumption time','Missing or dying agent → ignore stale request','Live agent → NavigationServer3D.map_get_path()','Budget limits queued requests; brain paths run separately']),
(60,550,700,210,'Example / remove slot 1',['Before: slots [0, 1, 2, 3] → IDs [10, 11, 12, 13]','die(1): move last slot and all related state to slot 1','After: visible slots [0, 1, 2] → IDs [10, 13, 12]']),
(840,550,700,210,'Example / consume ID 13',['ID 13 now resolves to slot 1; animation phase is preserved','ID 11 resolves to -1; its queued work is discarded','MultiMesh allocation stays; visible_instance_count decreases']),
],['M410 450V550','M1190 450V550','M760 650H840'],[
'Source: Horde.cell_of(), rebuild_spatial_hash(), process_path_requests(), die(), resolve_zombie().',
'Tradeoffs: resolve_zombie() scans IDs; large queues and dense spatial cells can reduce the benefit of batching.'
])
print('Generated 3 SVG diagrams in',OUT)

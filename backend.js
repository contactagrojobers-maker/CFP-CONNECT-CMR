(function(){
  const config=window.CFP_CONFIG||{};
  let client=null;
  const slugify=s=>(s||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'');
  function init(){
    if(!window.supabase?.createClient||!config.supabaseUrl||!config.supabasePublishableKey)return false;
    client=window.supabase.createClient(config.supabaseUrl,config.supabasePublishableKey,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
    return true;
  }
  async function session(){if(!client)return null;const {data}=await client.auth.getSession();return data.session}
  async function signIn(identifier,password){
    if(!client)throw new Error('Connexion Supabase indisponible.');
    const credentials=identifier.includes('@')?{email:identifier,password}:{phone:identifier,password};
    const {data,error}=await client.auth.signInWithPassword(credentials);if(error)throw error;return data;
  }
  async function signOut(){if(client)await client.auth.signOut()}
  async function profile(userId){if(!client||!userId)return null;const {data,error}=await client.from('profiles').select('id,full_name,phone,role').eq('id',userId).maybeSingle();if(error)throw error;return data}
  async function managedCenterIds(userId){if(!client||!userId)return[];const {data,error}=await client.from('center_managers').select('center_id').eq('user_id',userId).not('approved_at','is',null);if(error)throw error;return(data||[]).map(x=>x.center_id)}
  function mapCenter(c){
    const city=c.cities||{};const department=city.departments||{};const region=department.regions||{};
    const programLinks=c.center_programs||[];
    return {id:c.id,slug:c.slug,name:c.name,short:c.acronym||c.name.slice(0,3).toUpperCase(),verified:!!c.accreditation_verified,type:c.center_type||'Centre professionnel',region:region.name||'Est',department:department.name||'Lom-et-Djérem',city:city.name||'Bertoua',district:c.district||'',rating:Number(c.average_rating||0),reviews:Number(c.review_count||0),phone:c.phone||'',whatsapp:c.whatsapp||'',nextIntake:c.next_intake||'À préciser',accreditation:c.accreditation_number||'À vérifier',about:c.description||'',programs:programLinks.map(x=>({name:x.programs?.name||'Formation',duration:x.duration||'À préciser',diploma:x.diploma||'À préciser',level:x.admission_level||'À préciser'})),colors:['#08634b','#ffc400'],initials:(c.acronym||c.name).slice(0,3).toUpperCase(),photoUrls:(c.center_photos||[]).map(p=>p.storage_path),source:'supabase'};
  }
  async function fetchCenters(includeAll=false){
    if(!client)return[];
    let q=client.from('centers').select('*,cities(name,departments(name,regions(name))),center_programs(duration,diploma,admission_level,programs(name)),center_photos(storage_path,is_cover,sort_order)').order('name');
    if(!includeAll)q=q.eq('status','published');
    const {data,error}=await q;if(error)throw error;return(data||[]).map(mapCenter);
  }
  async function submitReview(centerId,name,rating,comment,userId){const {error}=await client.from('reviews').insert({center_id:centerId,author_id:userId,author_name:name,rating,comment,status:'pending'});if(error)throw error}
  async function submitContact(payload){const {error}=await client.from('contact_requests').insert(payload);if(error)throw error}
  async function cityId(name='Bertoua'){const {data,error}=await client.from('cities').select('id').eq('name',name).maybeSingle();if(error)throw error;return data?.id}
  async function saveCenter(center){
    const payload={name:center.name,slug:center.slug||slugify(center.name),acronym:center.short||null,center_type:center.type||'Centre professionnel',district:center.district||null,description:center.about||null,phone:center.phone||null,whatsapp:center.whatsapp||null,accreditation_number:center.accreditation||null,accreditation_verified:!!center.verified,next_intake:center.nextIntake||null,status:'published',city_id:await cityId(center.city)};
    let id=center.id;if(id&&String(id).startsWith('admin-'))id=null;
    const response=id?await client.from('centers').update(payload).eq('id',id).select('id').single():await client.from('centers').insert(payload).select('id').single();
    if(response.error)throw response.error;const savedId=response.data.id;
    if(Array.isArray(center.programs)){
      const clean=center.programs.map(p=>typeof p==='string'?{name:p}:p).filter(p=>p.name);
      const names=clean.map(p=>p.name);
      if(names.length){const {data:programRows,error:programError}=await client.from('programs').upsert(names.map(name=>({name})),{onConflict:'name'}).select('id,name');if(programError)throw programError;const {error:deleteError}=await client.from('center_programs').delete().eq('center_id',savedId);if(deleteError)throw deleteError;const links=programRows.map(row=>{const source=clean.find(p=>p.name===row.name)||{};return{center_id:savedId,program_id:row.id,duration:source.duration||'À préciser',diploma:source.diploma||'À préciser',admission_level:source.level||'À préciser'}});const {error:linkError}=await client.from('center_programs').insert(links);if(linkError)throw linkError}}
    return savedId;
  }
  window.CFPBackend={init,session,signIn,signOut,profile,managedCenterIds,fetchCenters,submitReview,submitContact,saveCenter,get client(){return client},get ready(){return!!client}};
})();

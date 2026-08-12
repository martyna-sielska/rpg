-- One-off: pushes the new items2.png-cropped icons (already in seed.sql)
-- to a database that was seeded before those icons existed. Safe to run
-- any number of times.
update public.items set icon_image = '/assets/items/ancient_seal.png' where id = 'ancient_seal';
update public.items set icon_image = '/assets/items/second_seal.png' where id = 'second_seal';
update public.items set icon_image = '/assets/items/third_seal.png' where id = 'third_seal';
update public.items set icon_image = '/assets/items/veil_key.png' where id = 'veil_key';
update public.items set icon_image = '/assets/items/rare_metal.png' where id = 'frost_iron';
update public.items set icon_image = '/assets/items/volcanic_material.png' where id = 'volcanic_glass';
update public.items set icon_image = '/assets/items/ancient_forge_fragment.png' where id = 'resonant_fragment';

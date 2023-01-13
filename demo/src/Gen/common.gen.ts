export function identity<T>(json: T): T {
    return json;
}

export function OptionalField_decode<T, T_JSON>(json: T_JSON | undefined, T_decode: (json: T_JSON) => T): T | undefined {
    if (json === undefined) return undefined;
    return T_decode(json);
}

export function OptionalField_encode<T, T_JSON>(entity: T | undefined, T_encode: (entity: T) => T_JSON): T_JSON | undefined {
    if (entity === undefined) return undefined;
    return T_encode(entity);
}

export function Optional_decode<T, T_JSON>(json: T_JSON | null, T_decode: (json: T_JSON) => T): T | null {
    if (json === null) return null;
    return T_decode(json);
}

export function Optional_encode<T, T_JSON>(entity: T | null, T_encode: (entity: T) => T_JSON): T_JSON | null {
    if (entity === null) return null;
    return T_encode(entity);
}

export function Array_decode<T, T_JSON>(json: T_JSON[], T_decode: (json: T_JSON) => T): T[] {
    return json.map(T_decode);
}

export function Array_encode<T, T_JSON>(entity: T[], T_encode: (entity: T) => T_JSON): T_JSON[] {
    return entity.map(T_encode);
}

export function Dictionary_decode<T, T_JSON>(json: {
    [key: string]: T_JSON;
}, T_decode: (json: T_JSON) => T): Map<string, T> {
    const entity = new Map<string, T>();
    for (const k in json) {
        if (json.hasOwnProperty(k)) {
            entity.set(k, T_decode(json[k]));
        }
    }
    return entity;
}

export function Dictionary_encode<T, T_JSON>(entity: Map<string, T>, T_encode: (entity: T) => T_JSON): {
    [key: string]: T_JSON;
} {
    const json: {
        [key: string]: T_JSON;
    } = {};
    for (const k in entity.keys()) {
        json[k] = T_encode(entity.get(k) !!);
    }
    return json;
}

export type TagOf<Type> = Type extends TagRecord<infer TAG>
    ? TAG
    : null extends Type
        ? "Optional" & TagOf<Exclude<Type, null>>
        : Type extends (infer E)[]
            ? "Array" & TagOf<E>
            : Type extends Map<string, infer V>
                ? "Dictionary" & TagOf<V>
                : never
;

export type TagRecord<Name extends string, Args extends any[] = []> = Args["length"] extends 0
    ? {
        $tag?: Name;
    }
    : {
        $tag?: Name & {
            [I in keyof Args]: TagOf<Args[I]>;
        };
    }
;

export function Date_encode(d: Date) {
    return d.getTime();
}

export function Date_decode(unixMilli: number) {
    return new Date(unixMilli);
}
